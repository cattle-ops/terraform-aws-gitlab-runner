[![Build Status](https://travis-ci.com/npalm/terraform-aws-gitlab-runner.svg?branch=master)](https://travis-ci.com/npalm/terraform-aws-gitlab-runner) [![Gitter](https://badges.gitter.im/terraform-aws-gitlab-runner/Lobby.svg)](https://gitter.im/terraform-aws-gitlab-runner/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

# Terraform module for GitLab auto scaling runners on AWS spot instances

> *WIP*: Work in progress, conversion to Terraform 0.12 \#73. Feel free to checkout branch [Terraform 0.12](https://github.com/npalm/terraform-aws-gitlab-runner/tree/feature/terraform-0.12).

> *NEW*: Multiple instnaces of the runner can be created that share the same cache. See [example](./examples/runner-public) *MIGRATIONS*: Since 3.7 the runner cache is handled by sub module. To avoid re-creation of the bucket while upgrading a state migration is need. Please see the migration script `./migrations/migration-state-3.7.x.sh`

This [Terraform](https://www.terraform.io/) modules creates a [GitLab CI runner](https://docs.gitlab.com/runner/). A blog post describes the original version of the the runner. See the post at [040code](https://040code.github.io/2017/12/09/runners-on-the-spot/). The original setup of the module is based on the blog post: [Auto scale GitLab CI runners and save 90% on EC2 costs](https://about.gitlab.com/2017/11/23/autoscale-ci-runners/).

The runners created by the module using by default spot instances for running the builds using the `docker+machine` executor.

  - Shared cache in S3 with life cycle management to clear objects after x days.
  - Logs streamed to CloudWatch.
  - Runner agents registered automatically.

The runner support 3 main scenario's:

### GitLab CI docker-machine runner - one runner agent

In this scenario the runner agent is running on a single EC2 node and runners are created by [docker machine](https://docs.gitlab.com/runner/configuration/autoscale.html) using spot instances. Runners will scale automatically based on configuration. The module creates by default a S3 cache that is shared cross runners (spot instances).

![runners-default](https://github.com/npalm/assets/raw/master/images/terraform-aws-gitlab-runner/runner-default.png)

### GitLab CI docker-machine runner - multiple runner agents

In this scenario the multiple runner agents can be created with different configuration by instantiating the module multiple times. Runners will scale automatically based on configuration. The S3 cache can be shared cross runners by managing the cache outside the module.

![runners-cache](https://github.com/npalm/assets/raw/master/images/terraform-aws-gitlab-runner/runner-cache.png)

### GitLab Ci docker runner

In this scenario *not* docker machine is used but docker to schedule the builds. Builds will run on the same EC2 instance as the agent. No auto scaling is supported.

![runners-docker](https://github.com/npalm/assets/raw/master/images/terraform-aws-gitlab-runner/runner-docker.png)

## Prerequisites

### Terraform

Ensure you have Terraform installed the modules is based on Terraform 0.11, see `.terraform-version` for the used version. A handy tool to mange your Terraform version is [tfenv](https://github.com/kamatama41/tfenv).

On macOS it is simple to install `tfenv` using brew.

``` sh
brew install tfenv
```

Next install a Terraform version.

``` sh
tfenv install <version>
```

### AWS

Ensure you have setup you AWS credentials. The module requires access to IAM, EC2, CloudWatch, S3 and SSM.

### Service linked roles

The GitLab runner EC2 instance requires the following service linked roles:

  - AWSServiceRoleForAutoScaling
  - AWSServiceRoleForEC2Spot

By default the EC2 instance is allowed to create the required roles, but this can be disabled by setting the option `allow_iam_service_linked_role_creation` to `false`. If disabled you must ensure the roles exist. You can create them manually or via Terraform.

``` hcl
resource "aws_iam_service_linked_role" "spot" {
  aws_service_name = "spot.amazonaws.com"
}

resource "aws_iam_service_linked_role" "autoscaling" {
  aws_service_name = "autoscaling.amazonaws.com"
}
```

### GitLab runner token configuration

By default the runner is registered on initial deployment. In previous versions of this module this was a manual process. The manual process is still supported but will be removed in future releases. The runner token will be stored in the parameter store. See [example](examples/runner-pre-registered/) for more details.

To register the runner automatically set the variable `gitlab_runner_registration_config["token"]`. This token value can be found in your GitLab project, group, or global settings. For a generic runner you can find the token in the admin section. By default the runner will be locked to the target project, not run untagged. Below is an example of the configuration map.

``` hcl
gitlab_runner_registration_config = {
  registration_token = "<registration token>"
  tag_list           = "<your tags, comma separated>"
  description        = "<some description>"
  locked_to_project  = "true"
  run_untagged       = "false"
  maximum_timeout    = "3600"
}
```

For migration to the new setup simply add the runner token to the parameter store. Once the runner is started it will lookup the required values via the parameter store. If the value is `null` a new runner will be created.

``` sh
# set the following variables, look up the variables in your Terraform config.
# see your Terraform variables to fill in the vars below.
aws-region=<${var.aws_region}>
token=<runner-token-see-your-gitlab-runner>
parameter-name=<${var.environment}>-<${var.secure_parameter_store_runner_token_key}>

aws ssm put-parameter --overwrite --type SecureString  --name "${parameter-name}" --value ${token} --region "${aws-region}"
```

Once you have created the parameter, you must remove the variable `runners_token` from your config. The next time your gitlab runner instance is created it will look up the token from the SSM parameter store.

Finally, the runner still supports the manual runner creation. No changes are required. Please keep in mind that this setup will be removed in future releases.

### GitLab runner cache

By default the module creates a a cache for the runner in S3. Old objects are automatically remove via a configurable life cycle policy on the bucket.

Creation of the bucket can be disabled and managed outside this module. A good use case is for sharing the cache cross multiple runners. For this purpose the cache is implemented as sub module. For more details see the [cache module](./cache). An example implementation of this use case can be find in the [runner-public](./examples/runner-public) example.

## Usage

### Configuration

Update the variables in `terraform.tfvars` according to your needs and add the following variables. See the previous step for instructions on how to obtain the token.

``` hcl
runner_name  = "NAME_OF_YOUR_RUNNER"
gitlab_url   = "GITLAB_URL"
runner_token = "RUNNER_TOKEN"
```

The base image used to host the GitLab Runner agent is the latest available Amazon Linux HVM EBS AMI. In previous versions of this module a hard coded list of AMIs per region was provided. This list has been replaced by a search filter to find the latest AMI. Setting the filter to `amzn-ami-hvm-2018.03.0.20180622-x86_64-ebs` will allow you to version lock the target AMI.

### Usage module

Below a basic examples of usages of the module. The dependencies such as a VPC, and SSH keys have a look at the [default example](./examples/runner-default).

``` hcl

module "runner" {
  source = "npalm/gitlab-runner/aws"
  version = "3.6.0"

  aws_region  = "eu-west-1"
  environment = "spot-runners"

  ssh_public_key = "${local_file.public_ssh_key.content}"

  vpc_id                   = "${module.vpc.vpc_id}"
  subnet_ids_gitlab_runner = "${module.vpc.private_subnets}"
  subnet_id_runners        = "${element(module.vpc.private_subnets, 0)}"

  runners_name       = "aws-spot-instance-runner"
  runners_gitlab_url = "https://gitlab.com"

  gitlab_runner_registration_config = {
    registration_token = "${var.registration_token}"
    tag_list           = "docker_spot_runner"
    description        = "runner default - auto"
    locked_to_project  = "true"
    run_untagged       = "false"
    maximum_timeout    = "3600"
  }
}
```

## Examples

A few [examples](examples) are provided. Use the following steps to deploy. Ensure your AWS and Terraform environment is set up correctly. All commands below should be run from the `terraform-aws-gitlab-runner/examples/<example-dir>` directory.

### SSH keys

SSH keys are generated by Terraform and stored in the `generated` directory of each example directory.

### Versions

THe version of Terraform is locked down via tfenv, see the `.terraform-version` file for the expected versions. Providers are locked down as will in the `providers.tf` file.

### Configure

The examples are configured with defaults that should wrk in general. THe samples are in general configured for the region Ireland `eu-west-1`. The only parameter that needs to be provided is the GitLab registration token. The token can be find in GitLab in the runner section (global, group or repo scope). Create a file `terrafrom.tfvars` and the registration token.

    registration_token = "MY_TOKEN"

### Run

Run `terraform init` to initialize Terraform. Next you can run `terraform plan` to inspect the resources that will be created.

To create the runner run:

``` sh
terraform apply
```

To destroy runner:

``` sh
terraform destroy
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| allow\_iam\_service\_linked\_role\_creation | Boolean used to control attaching the policy to a runner instance to create service linked roles. | string | `"true"` | no |
| ami\_filter | List of maps used to create the AMI filter for the Gitlab runner agent AMI. Currently Amazon Linux 2 `amzn2-ami-hvm-2.0.????????-x86_64-ebs` looks to *not* be working for this configuration. | map(list(string)) | `<map>` | no |
| ami\_owners | The list of owners used to select the AMI of Gitlab runner agent instances. | list(string) | `<list>` | no |
| aws\_region | AWS region. | string | n/a | yes |
| aws\_zone | AWS availability zone (typically 'a', 'b', or 'c'). | string | `"a"` | no |
| cache\_bucket | Configuration to control the creation of th the cache bucket. By default the bucket will be crated and used as shared cache. To use the same cache cross multiple runners disable the cration of the cache and provice a policy and bucket name. See the public runner example for more details. | map | `<map>` | no |
| cache\_bucket\_prefix | Prefix for s3 cache bucket name. | string | `""` | no |
| cache\_bucket\_versioning | Boolean used to enable versioning on the cache bucket, false by default. | string | `"false"` | no |
| cache\_expiration\_days | Number of days before cache objects expires. | string | `"1"` | no |
| cache\_shared | Enables cache sharing between runners, false by default. | string | `"false"` | no |
| create\_runners\_iam\_instance\_profile | Boolean to control the creation of the runners IAM instance profile | string | `"true"` | no |
| docker\_machine\_instance\_type | Instance type used for the instances hosting docker-machine. | string | `"m5a.large"` | no |
| docker\_machine\_options | List of additional options for the docker machine config. Each element of this list must be a key=value pair. E.g. '["amazonec2-zone=a"]' | list(string) | `<list>` | no |
| docker\_machine\_role\_json | Docker machine runner instance override policy, expected to be in JSON format. | string | `""` | no |
| docker\_machine\_spot\_price\_bid | Spot price bid. | string | `"0.06"` | no |
| docker\_machine\_ssh\_cidr\_blocks | List of CIDR blocks to allow SSH Access to the docker machine runner instance. | list(string) | `<list>` | no |
| docker\_machine\_user | Username of the user used to create the spot instances that host docker-machine. | string | `"docker-machine"` | no |
| docker\_machine\_version | Version of docker-machine. | string | `"0.16.1"` | no |
| enable\_cloudwatch\_logging | Boolean used to enable or disable the CloudWatch logging. | string | `"true"` | no |
| enable\_gitlab\_runner\_ssh\_access | Enables SSH Access to the gitlab runner instance. | string | `"false"` | no |
| enable\_manage\_gitlab\_token | Boolean to enable the management of the GitLab token in SSM. If `true` the token will be stored in SSM, which means the SSM property is a terraform managed resource. If `false` the Gitlab token will be stored in the SSM by the user-data script during creation of the the instance. However the SSM parameter is not managed by terraform and will remain in SSM after a `terraform destroy`. | string | `"true"` | no |
| environment | A name that identifies the environment, used as prefix and for tagging. | string | n/a | yes |
| gitlab\_runner\_registration\_config | Configuration used to register the runner. See the README for an example, or reference the examples in the examples directory of this repo. | map(string) | `<map>` | no |
| gitlab\_runner\_ssh\_cidr\_blocks | List of CIDR blocks to allow SSH Access to the gitlab runner instance. | list(string) | `<list>` | no |
| gitlab\_runner\_version | Version of the GitLab runner. | string | `"11.11.2"` | no |
| instance\_role\_json | Default runner instance override policy, expected to be in JSON format. | string | `""` | no |
| instance\_type | Instance type used for the GitLab runner. | string | `"t3.micro"` | no |
| name\_runners\_docker\_machine |  | string | `""` | no |
| overrides | This maps provides the possibility to override some defaults. The following attributes are supported: `name_sg` overwrite the `Name` tag for all security groups created by this module. `name_runner_agent_instance` override the `Name` tag for the ec2 instance defined in the auto launch configuration. `name_docker_machine_runners` ovverrid the `Name` tag spot instances created by the runner agent. | map(string) | `<map>` | no |
| runner\_ami\_filter | List of maps used to create the AMI filter for the Gitlab runner docker-machine AMI. | map(list(string)) | `<map>` | no |
| runner\_ami\_owners | The list of owners used to select the AMI of Gitlab runner docker-machine instances. | list(string) | `<list>` | no |
| runner\_instance\_spot\_price | By setting a spot price bid price the runner agent will be created via a spot request. Be aware that spot instances can be stopped by AWS. | string | `""` | no |
| runners\_concurrent | Concurrent value for the runners, will be used in the runner config.toml. | string | `"10"` | no |
| runners\_docker\_socket | Location of Docker socket on host if socket mount if enabled, will be used in the runner config.toml | string | `"/var/run/docker.sock:/var/run/docker.sock"` | no |
| runners\_environment\_vars | Environment variables during build execution, e.g. KEY=Value, see runner-public example. Will be used in the runner config.toml | list(string) | `<list>` | no |
| runners\_executor | The executor to use. Currently supports `docker+machine` or `docker`. | string | `"docker+machine"` | no |
| runners\_gitlab\_url | URL of the GitLab instance to connect to. | string | n/a | yes |
| runners\_iam\_instance\_profile\_name | IAM instance profile name of the runners, will be used in the runner config.toml | string | `""` | no |
| runners\_idle\_count | Idle count of the runners, will be used in the runner config.toml. | string | `"0"` | no |
| runners\_idle\_time | Idle time of the runners, will be used in the runner config.toml. | string | `"600"` | no |
| runners\_image | Image to run builds, will be used in the runner config.toml | string | `"docker:18.03.1-ce"` | no |
| runners\_limit | Limit for the runners, will be used in the runner config.toml. | string | `"0"` | no |
| runners\_monitoring | Enable detailed cloudwatch monitoring for spot instances. | string | `"false"` | no |
| runners\_mount\_docker\_socket | Runners will mount volume with Docker socket, will be used in the runner config.toml | string | `"false"` | no |
| runners\_name | Name of the runner, will be used in the runner config.toml. | string | n/a | yes |
| runners\_off\_peak\_idle\_count | Off peak idle count of the runners, will be used in the runner config.toml. | string | `"0"` | no |
| runners\_off\_peak\_idle\_time | Off peak idle time of the runners, will be used in the runner config.toml. | string | `"0"` | no |
| runners\_off\_peak\_periods | Off peak periods of the runners, will be used in the runner config.toml. | string | `""` | no |
| runners\_off\_peak\_timezone | Off peak idle time zone of the runners, will be used in the runner config.toml. | string | `""` | no |
| runners\_output\_limit | Sets the maximum build log size in kilobytes, by default set to 4096 (4MB) | string | `"4096"` | no |
| runners\_post\_build\_script | Commands to be executed on the Runner just after executing the build, but before executing after_script. | string | `""` | no |
| runners\_pre\_build\_script | Script to execute in the pipeline just before the build, will be used in the runner config.toml | string | `""` | no |
| runners\_pre\_clone\_script | Commands to be executed on the Runner before cloning the Git repository. this can be used to adjust the Git client configuration first, for example. | string | `""` | no |
| runners\_privileged | Runners will run in privileged mode, will be used in the runner config.toml | string | `"true"` | no |
| runners\_pull\_policy | pull_policy for the runners, will be used in the runner config.toml | string | `"always"` | no |
| runners\_request\_concurrency | Limit number of concurrent requests for new jobs from GitLab (default 1) | string | `"1"` | no |
| runners\_root\_size | Runner instance root size in GB. | string | `"16"` | no |
| runners\_shm\_size | shm_size for the runners, will be used in the runner config.toml | string | `"0"` | no |
| runners\_token | Token for the runner, will be used in the runner config.toml. | string | `"__REPLACED_BY_USER_DATA__"` | no |
| runners\_use\_private\_address | Restrict runners to the use of a private IP address | string | `"true"` | no |
| secure\_parameter\_store\_runner\_token\_key | The key name used store the Gitlab runner token in Secure Parameter Store | string | `"runner-token"` | no |
| ssh\_key\_pair | Set this to use existing AWS key pair | string | `""` | no |
| ssh\_public\_key | Public SSH key used for the GitLab runner EC2 instance. | string | n/a | yes |
| subnet\_id\_runners | List of subnets used for hosting the gitlab-runners. | string | n/a | yes |
| subnet\_ids\_gitlab\_runner | Subnet used for hosting the GitLab runner. | list(string) | n/a | yes |
| tags | Map of tags that will be added to created resources. By default resources will be tagged with name and environment. | map(string) | `<map>` | no |
| userdata\_post\_install | User-data script snippet to insert after GitLab runner install | string | `""` | no |
| userdata\_pre\_install | User-data script snippet to insert before GitLab runner install | string | `""` | no |
| vpc\_id | The target VPC for the docker-machine and runner instances. | string | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| runner\_agent\_role | ARN of the rule used for the ec2 instance for the GitLab runner agent. |
| runner\_as\_group\_name | Name of the autoscaling group for the gitlab-runner instance |
| runner\_cache\_bucket\_arn | ARN of the S3 for the build cache. |
| runner\_role | ARN of the rule used for the docker machine runners. |

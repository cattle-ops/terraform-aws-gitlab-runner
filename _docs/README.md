[![Terraform registry](https://img.shields.io/github/v/release/npalm/terraform-aws-gitlab-runner?label=Terraform%20Registry)](https://registry.terraform.io/modules/npalm/gitlab-runner/aws/) [![Gitter](https://badges.gitter.im/terraform-aws-gitlab-runner/Lobby.svg)](https://gitter.im/terraform-aws-gitlab-runner/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge) [![Actions](https://github.com/npalm/terraform-aws-gitlab-runner/workflows/Verify/badge.svg)](https://github.com/npalm/terraform-aws-gitlab-runner/actions)


# Terraform module for GitLab auto scaling runners on AWS spot instances

> *NEW*: Terraform 0.12 is supported.

## Terraform versions

### Terraform 0.12
Module is available as Terraform 0.12 module, pin to version 4.x. Please submit pull-requests to the `develop` branch.

Migration from 0.11 to 0.12 is tested for the `runner-default` example. To migrate the runner, execute the following steps.

- Update to Terraform 0.12
- Migrate your Terraform code via Terraform `terraform 0.12upgrade`.
- Update the module from 3.10.0 to 4.0.0, next run `terraform init`
- Run `terraform apply`. This should trigger only a re-creation of the the auto launch configuration and a minor change in the auto-scaling group.

### Terraform 0.11
Module is available as Terraform 0.11 module, pin module to version 3.x. Please submit pull-requests to the `terraform011` branch.

## The module

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

Creation of the bucket can be disabled and managed outside this module. A good use case is for sharing the cache cross multiple runners. For this purpose the cache is implemented as sub module. For more details see the [cache module](https://github.com/npalm/terraform-aws-gitlab-runner/tree/__GIT_REF__/cache). An example implementation of this use case can be find in the [runner-public](https://github.com/npalm/terraform-aws-gitlab-runner/tree/__GIT_REF__/examples/runner-public) example.

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

Below a basic examples of usages of the module. The dependencies such as a VPC, and SSH keys have a look at the [default example](https://github.com/npalm/terraform-aws-gitlab-runner/tree/__GIT_REF__/examples/runner-default).

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

A few [examples]([examples](https://github.com/npalm/terraform-aws-gitlab-runner/tree/__GIT_REF__/examples/) are provided. Use the following steps to deploy. Ensure your AWS and Terraform environment is set up correctly. All commands below should be run from the `terraform-aws-gitlab-runner/examples/<example-dir>` directory.

### SSH keys

SSH keys are generated by Terraform and stored in the `generated` directory of each example directory.

### Versions

THe version of Terraform is locked down via tfenv, see the `.terraform-version` file for the expected versions. Providers are locked down as will in the `providers.tf` file.

### Configure

The examples are configured with defaults that should wrk in general. THe samples are in general configured for the region Ireland `eu-west-1`. The only parameter that needs to be provided is the GitLab registration token. The token can be find in GitLab in the runner section (global, group or repo scope). Create a file `terrafrom.tfvars` and the registration token.

```
registration_token = "MY_TOKEN"
```

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

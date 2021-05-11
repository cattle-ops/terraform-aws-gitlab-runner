[![Terraform registry](https://img.shields.io/github/v/release/npalm/terraform-aws-gitlab-runner?label=Terraform%20Registry)](https://registry.terraform.io/modules/npalm/gitlab-runner/aws/) [![Gitter](https://badges.gitter.im/terraform-aws-gitlab-runner/Lobby.svg)](https://gitter.im/terraform-aws-gitlab-runner/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge) [![Actions](https://github.com/npalm/terraform-aws-gitlab-runner/workflows/Verify/badge.svg)](https://github.com/npalm/terraform-aws-gitlab-runner/actions)

# Terraform module for GitLab auto scaling runners on AWS spot instances <!-- omit in toc -->

- [The module](#the-module)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
- [Examples](#examples)
- [Requirements](#requirements)
- [Providers](#providers)
- [Modules](#modules)
- [Resources](#resources)
- [Inputs](#inputs)
- [Outputs](#outputs)
- [Contributors ✨](#contributors-)

## The module

This [Terraform](https://www.terraform.io/) modules creates a [GitLab CI runner](https://docs.gitlab.com/runner/). A blog post describes the original version of the the runner. See the post at [040code](https://040code.github.io/2017/12/09/runners-on-the-spot/). The original setup of the module is based on the blog post: [Auto scale GitLab CI runners and save 90% on EC2 costs](https://about.gitlab.com/2017/11/23/autoscale-ci-runners/).

The runners created by the module use spot instances by default for running the builds using the `docker+machine` executor.

- Shared cache in S3 with life cycle management to clear objects after x days.
- Logs streamed to CloudWatch.
- Runner agents registered automatically.

The name of the runner agent and runner is set with the overrides variable. Adding an agent runner name tag does not work.

```hcl
...
overrides  = {
  name_sg                     = ""
  name_runner_agent_instance  = "Gitlab Runner Agent"
  name_docker_machine_runners = "Gitlab Runner Terraform"
}

//this doesn't work
agent_tags = merge(local.my_tags, map("Name", "Gitlab Runner Agent"))
```

The runner supports 3 main scenarios:

### GitLab CI docker-machine runner - one runner agent

In this scenario the runner agent is running on a single EC2 node and runners are created by [docker machine](https://docs.gitlab.com/runner/configuration/autoscale.html) using spot instances. Runners will scale automatically based on the configuration. The module creates a S3 cache by default, which is shared across runners (spot instances).

![runners-default](https://github.com/npalm/assets/raw/master/images/terraform-aws-gitlab-runner/runner-default.png)

### GitLab CI docker-machine runner - multiple runner agents

In this scenario the multiple runner agents can be created with different configuration by instantiating the module multiple times. Runners will scale automatically based on the configuration. The S3 cache can be shared across runners by managing the cache outside of the module.

![runners-cache](https://github.com/npalm/assets/raw/master/images/terraform-aws-gitlab-runner/runner-cache.png)

### GitLab Ci docker runner

In this scenario _not_ docker machine is used but docker to schedule the builds. Builds will run on the same EC2 instance as the agent. No auto scaling is supported.

![runners-docker](https://github.com/npalm/assets/raw/master/images/terraform-aws-gitlab-runner/runner-docker.png)

## Prerequisites

### Terraform

Ensure you have Terraform installed. The modules is based on Terraform 0.11, see `.terraform-version` for the used version. A handy tool to mange your Terraform version is [tfenv](https://github.com/kamatama41/tfenv).

On macOS it is simple to install `tfenv` using `brew`.

```sh
brew install tfenv
```

Next install a Terraform version.

```sh
tfenv install <version>
```

### AWS

Ensure you have setup your AWS credentials. The module requires access to IAM, EC2, CloudWatch, S3 and SSM.

### JQ & AWS CLI

In order to be able to destroy the module, you will need to run from a host with both `jq` and `aws` installed and accessible in the environment.

On macOS it is simple to install them using `brew`.

```sh
brew install jq awscli
```

### Service linked roles

The GitLab runner EC2 instance requires the following service linked roles:

- AWSServiceRoleForAutoScaling
- AWSServiceRoleForEC2Spot

By default the EC2 instance is allowed to create the required roles, but this can be disabled by setting the option `allow_iam_service_linked_role_creation` to `false`. If disabled you must ensure the roles exist. You can create them manually or via Terraform.

```hcl
resource "aws_iam_service_linked_role" "spot" {
  aws_service_name = "spot.amazonaws.com"
}

resource "aws_iam_service_linked_role" "autoscaling" {
  aws_service_name = "autoscaling.amazonaws.com"
}
```

### GitLab runner token configuration

By default the runner is registered on initial deployment. In previous versions of this module this was a manual process. The manual process is still supported but will be removed in future releases. The runner token will be stored in the AWS SSM parameter store. See [example](examples/runner-pre-registered/) for more details.

To register the runner automatically set the variable `gitlab_runner_registration_config["registration_token"]`. This token value can be found in your GitLab project, group, or global settings. For a generic runner you can find the token in the admin section. By default the runner will be locked to the target project, not run untagged. Below is an example of the configuration map.

```hcl
gitlab_runner_registration_config = {
  registration_token = "<registration token>"
  tag_list           = "<your tags, comma separated>"
  description        = "<some description>"
  locked_to_project  = "true"
  run_untagged       = "false"
  maximum_timeout    = "3600"
  access_level       = "<not_protected OR ref_protected, ref_protected runner will only run on pipelines triggered on protected branches. Defaults to not_protected>"
}
```

For migration to the new setup simply add the runner token to the parameter store. Once the runner is started it will lookup the required values via the parameter store. If the value is `null` a new runner will be registered and a new token created/stored.

```sh
# set the following variables, look up the variables in your Terraform config.
# see your Terraform variables to fill in the vars below.
aws-region=<${var.aws_region}>
token=<runner-token-see-your-gitlab-runner>
parameter-name=<${var.environment}>-<${var.secure_parameter_store_runner_token_key}>

aws ssm put-parameter --overwrite --type SecureString  --name "${parameter-name}" --value ${token} --region "${aws-region}"
```

Once you have created the parameter, you must remove the variable `runners_token` from your config. The next time your GitLab runner instance is created it will look up the token from the SSM parameter store.

Finally, the runner still supports the manual runner creation. No changes are required. Please keep in mind that this setup will be removed in future releases.

### Access runner instance

A few option are provided to access the runner instance:

1.  Provide a public ssh key to access the runner by setting \`\`.
2.  Provide a EC2 key pair to access the runner by setting \`\`.
3.  Access via the Session Manager (SSM) by setting `enable_runner_ssm_access` to `true`. The policy to allow access via SSM is not very restrictive.
4.  By setting none of the above, no keys or extra policies will be attached to the instance. You can still configure you own policies by attaching them to `runner_agent_role_arn`.

### GitLab runner cache

By default the module creates a a cache for the runner in S3. Old objects are automatically removed via a configurable life cycle policy on the bucket.

Creation of the bucket can be disabled and managed outside this module. A good use case is for sharing the cache across multiple runners. For this purpose the cache is implemented as a sub module. For more details see the [cache module](https://github.com/npalm/terraform-aws-gitlab-runner/tree/develop/cache). An example implementation of this use case can be found in the [runner-public](https://github.com/npalm/terraform-aws-gitlab-runner/tree/__GIT_REF__/examples/runner-public) example.

## Usage

### Configuration

Update the variables in `terraform.tfvars` according to your needs and add the following variables. See the previous step for instructions on how to obtain the token.

```hcl
runner_name  = "NAME_OF_YOUR_RUNNER"
gitlab_url   = "GITLAB_URL"
runner_token = "RUNNER_TOKEN"
```

The base image used to host the GitLab Runner agent is the latest available Amazon Linux 2 HVM EBS AMI. In previous versions of this module a hard coded list of AMIs per region was provided. This list has been replaced by a search filter to find the latest AMI. Setting the filter to `amzn2-ami-hvm-2.0.20200207.1-x86_64-ebs` will allow you to version lock the target AMI.

### Usage module

Below is a basic examples of usages of the module. Regarding the dependencies such as a VPC and SSH keys, have a look at the [default example](https://github.com/npalm/terraform-aws-gitlab-runner/tree/develop/examples/runner-default).

```hcl
module "runner" {
  # https://registry.terraform.io/modules/npalm/gitlab-runner/aws/
  source  = "npalm/gitlab-runner/aws"

  aws_region  = "eu-west-1"
  environment = "spot-runners"

  ssh_public_key = local_file.public_ssh_key.content

  vpc_id                   = module.vpc.vpc_id
  subnet_ids_gitlab_runner = module.vpc.private_subnets
  subnet_id_runners        = element(module.vpc.private_subnets, 0)

  runners_name       = "docker-default"
  runners_gitlab_url = "https://gitlab.com"

  gitlab_runner_registration_config = {
    registration_token = "my-token
    tag_list           = "docker"
    description        = "runner default"
    locked_to_project  = "true"
    run_untagged       = "false"
    maximum_timeout    = "3600"
  }

}
```

## Examples

A few [examples](https://github.com/npalm/terraform-aws-gitlab-runner/tree/develop/examples/) are provided. Use the following steps to deploy. Ensure your AWS and Terraform environment is set up correctly. All commands below should be run from the `terraform-aws-gitlab-runner/examples/<example-dir>` directory.

### SSH keys

SSH keys are generated by Terraform and stored in the `generated` directory of each example directory.

### Versions

The version of Terraform is locked down via tfenv, see the `.terraform-version` file for the expected versions. Providers are locked down as well in the `providers.tf` file.

### Configure

The examples are configured with defaults that should work in general. The examples are in general configured for the region Ireland `eu-west-1`. The only parameter that needs to be provided is the GitLab registration token. The token can be found in GitLab in the runner section (global, group or repo scope). Create a file `terrafrom.tfvars` and the registration token.

    registration_token = "MY_TOKEN"

### Run

Run `terraform init` to initialize Terraform. Next you can run `terraform plan` to inspect the resources that will be created.

To create the runner, run:

```sh
terraform apply
```

To destroy the runner, run:

```sh
terraform destroy
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12 |
| aws | >= 3.35.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 3.35.0 |
| null | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| cache | ./modules/cache |  |

## Resources

| Name |
|------|
| [aws_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) |
| [aws_autoscaling_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) |
| [aws_autoscaling_schedule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_schedule) |
| [aws_availability_zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zone) |
| [aws_caller_identity](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) |
| [aws_cloudwatch_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) |
| [aws_eip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) |
| [aws_iam_instance_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) |
| [aws_iam_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) |
| [aws_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) |
| [aws_iam_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) |
| [aws_iam_role_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) |
| [aws_kms_alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) |
| [aws_kms_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) |
| [aws_launch_configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_configuration) |
| [aws_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) |
| [aws_security_group_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) |
| [aws_ssm_parameter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) |
| [aws_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) |
| [null_data_source](https://registry.terraform.io/providers/hashicorp/null/latest/docs/data-sources/data_source) |
| [null_resource](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| agent\_tags | Map of tags that will be added to agent EC2 instances. | `map(string)` | `{}` | no |
| allow\_iam\_service\_linked\_role\_creation | Boolean used to control attaching the policy to a runner instance to create service linked roles. | `bool` | `true` | no |
| ami\_filter | List of maps used to create the AMI filter for the Gitlab runner agent AMI. Must resolve to an Amazon Linux 1 or 2 image. | `map(list(string))` | <pre>{<br>  "name": [<br>    "amzn2-ami-hvm-2.*-x86_64-ebs"<br>  ]<br>}</pre> | no |
| ami\_owners | The list of owners used to select the AMI of Gitlab runner agent instances. | `list(string)` | <pre>[<br>  "amazon"<br>]</pre> | no |
| arn\_format | ARN format to be used. May be changed to support deployment in GovCloud/China regions. | `string` | `"arn:aws"` | no |
| asg\_delete\_timeout | Timeout when trying to delete the Runner ASG. | `string` | `"10m"` | no |
| aws\_region | AWS region. | `string` | n/a | yes |
| aws\_zone | Deprecated. Will be removed in the next major release. | `string` | `"a"` | no |
| cache\_bucket | Configuration to control the creation of the cache bucket. By default the bucket will be created and used as shared cache. To use the same cache across multiple runners disable the creation of the cache and provide a policy and bucket name. See the public runner example for more details. | `map(any)` | <pre>{<br>  "bucket": "",<br>  "create": true,<br>  "policy": ""<br>}</pre> | no |
| cache\_bucket\_name\_include\_account\_id | Boolean to add current account ID to cache bucket name. | `bool` | `true` | no |
| cache\_bucket\_prefix | Prefix for s3 cache bucket name. | `string` | `""` | no |
| cache\_bucket\_set\_random\_suffix | Append the cache bucket name with a random string suffix | `bool` | `false` | no |
| cache\_bucket\_versioning | Boolean used to enable versioning on the cache bucket, false by default. | `bool` | `false` | no |
| cache\_expiration\_days | Number of days before cache objects expires. | `number` | `1` | no |
| cache\_shared | Enables cache sharing between runners, false by default. | `bool` | `false` | no |
| cloudwatch\_logging\_retention\_in\_days | Retention for cloudwatch logs. Defaults to unlimited | `number` | `0` | no |
| docker\_machine\_download\_url | Full url pointing to a linux x64 distribution of docker machine. Once set `docker_machine_version` will be ingored. For example the GitLab version, https://gitlab-docker-machine-downloads.s3.amazonaws.com/v0.16.2-gitlab.2/docker-machine. | `string` | `"https://gitlab-docker-machine-downloads.s3.amazonaws.com/v0.16.2-gitlab.2/docker-machine"` | no |
| docker\_machine\_iam\_policy\_arns | List of policy ARNs to be added to the instance profile of the docker machine runners. | `list(string)` | `[]` | no |
| docker\_machine\_instance\_type | Instance type used for the instances hosting docker-machine. | `string` | `"m5.large"` | no |
| docker\_machine\_options | List of additional options for the docker machine config. Each element of this list must be a key=value pair. E.g. '["amazonec2-zone=a"]' | `list(string)` | `[]` | no |
| docker\_machine\_role\_json | Docker machine runner instance override policy, expected to be in JSON format. | `string` | `""` | no |
| docker\_machine\_security\_group\_description | A description for the docker-machine security group | `string` | `"A security group containing docker-machine instances"` | no |
| docker\_machine\_spot\_price\_bid | Spot price bid. | `string` | `"0.06"` | no |
| docker\_machine\_version | By default docker\_machine\_download\_url is used to set the docker machine version. Version of docker-machine. The version will be ingored once `docker_machine_download_url` is set. | `string` | `""` | no |
| enable\_asg\_recreation | Enable automatic redeployment of the Runner ASG when the Launch Configs change. | `bool` | `true` | no |
| enable\_cloudwatch\_logging | Boolean used to enable or disable the CloudWatch logging. | `bool` | `true` | no |
| enable\_docker\_machine\_ssm\_access | Add IAM policies to the docker-machine instances to connect via the Session Manager. | `bool` | `false` | no |
| enable\_eip | Enable the assignment of an EIP to the gitlab runner instance | `bool` | `false` | no |
| enable\_forced\_updates | DEPRECATED! and is replaced by `enable_asg_recreation. Setting this variable to true will do the oposite as expected. For backward compatibility the variable will remain some releases. Old desription: Enable automatic redeployment of the Runner ASG when the Launch Configs change.` | `string` | `null` | no |
| enable\_gitlab\_runner\_ssh\_access | Enables SSH Access to the gitlab runner instance. | `bool` | `false` | no |
| enable\_kms | Let the module manage a KMS key, logs will be encrypted via KMS. Be-aware of the costs of an custom key. | `bool` | `false` | no |
| enable\_manage\_gitlab\_token | Boolean to enable the management of the GitLab token in SSM. If `true` the token will be stored in SSM, which means the SSM property is a terraform managed resource. If `false` the Gitlab token will be stored in the SSM by the user-data script during creation of the the instance. However the SSM parameter is not managed by terraform and will remain in SSM after a `terraform destroy`. | `bool` | `true` | no |
| enable\_ping | Allow ICMP Ping to the ec2 instances. | `bool` | `false` | no |
| enable\_runner\_ssm\_access | Add IAM policies to the runner agent instance to connect via the Session Manager. | `bool` | `false` | no |
| enable\_runner\_user\_data\_trace\_log | Enable bash xtrace for the user data script that creates the EC2 instance for the runner agent. Be aware this could log sensitive data such as you GitLab runner token. | `bool` | `false` | no |
| enable\_schedule | Flag used to enable/disable auto scaling group schedule for the runner instance. | `bool` | `false` | no |
| environment | A name that identifies the environment, used as prefix and for tagging. | `string` | n/a | yes |
| gitlab\_runner\_egress\_rules | List of egress rules for the gitlab runner instance. | <pre>list(object({<br>    cidr_blocks      = list(string)<br>    ipv6_cidr_blocks = list(string)<br>    prefix_list_ids  = list(string)<br>    from_port        = number<br>    protocol         = string<br>    security_groups  = list(string)<br>    self             = bool<br>    to_port          = number<br>    description      = string<br>  }))</pre> | <pre>[<br>  {<br>    "cidr_blocks": [<br>      "0.0.0.0/0"<br>    ],<br>    "description": null,<br>    "from_port": 0,<br>    "ipv6_cidr_blocks": [<br>      "::/0"<br>    ],<br>    "prefix_list_ids": null,<br>    "protocol": "-1",<br>    "security_groups": null,<br>    "self": null,<br>    "to_port": 0<br>  }<br>]</pre> | no |
| gitlab\_runner\_registration\_config | Configuration used to register the runner. See the README for an example, or reference the examples in the examples directory of this repo. | `map(string)` | <pre>{<br>  "access_level": "",<br>  "description": "",<br>  "locked_to_project": "",<br>  "maximum_timeout": "",<br>  "registration_token": "",<br>  "run_untagged": "",<br>  "tag_list": ""<br>}</pre> | no |
| gitlab\_runner\_security\_group\_description | A description for the gitlab-runner security group | `string` | `"A security group containing gitlab-runner agent instances"` | no |
| gitlab\_runner\_security\_group\_ids | A list of security group ids that are allowed to access the gitlab runner agent | `list(string)` | `[]` | no |
| gitlab\_runner\_ssh\_cidr\_blocks | List of CIDR blocks to allow SSH Access to the gitlab runner instance. | `list(string)` | `[]` | no |
| gitlab\_runner\_version | Version of the GitLab runner. | `string` | `"13.8.0"` | no |
| instance\_role\_json | Default runner instance override policy, expected to be in JSON format. | `string` | `""` | no |
| instance\_type | Instance type used for the GitLab runner. | `string` | `"t3.micro"` | no |
| kms\_alias\_name | Alias added to the kms\_key (if created and not provided by kms\_key\_id) | `string` | `""` | no |
| kms\_deletion\_window\_in\_days | Key rotation window, set to 0 for no rotation. Only used when `enable_kms` is set to `true`. | `number` | `7` | no |
| kms\_key\_id | KMS key id to encrypted the CloudWatch logs. Ensure CloudWatch has access to the provided KMS key. | `string` | `""` | no |
| log\_group\_name | Option to override the default name (`environment`) of the log group, requires `enable_cloudwatch_logging = true`. | `string` | `null` | no |
| metrics\_autoscaling | A list of metrics to collect. The allowed values are GroupDesiredCapacity, GroupInServiceCapacity, GroupPendingCapacity, GroupMinSize, GroupMaxSize, GroupInServiceInstances, GroupPendingInstances, GroupStandbyInstances, GroupStandbyCapacity, GroupTerminatingCapacity, GroupTerminatingInstances, GroupTotalCapacity, GroupTotalInstances. | `list(string)` | `null` | no |
| overrides | This maps provides the possibility to override some defaults. The following attributes are supported: `name_sg` overwrite the `Name` tag for all security groups created by this module. `name_runner_agent_instance` override the `Name` tag for the ec2 instance defined in the auto launch configuration. `name_docker_machine_runners` ovverrid the `Name` tag spot instances created by the runner agent. | `map(string)` | <pre>{<br>  "name_docker_machine_runners": "",<br>  "name_runner_agent_instance": "",<br>  "name_sg": ""<br>}</pre> | no |
| permissions\_boundary | Name of permissions boundary policy to attach to AWS IAM roles | `string` | `""` | no |
| runner\_ami\_filter | List of maps used to create the AMI filter for the Gitlab runner docker-machine AMI. | `map(list(string))` | <pre>{<br>  "name": [<br>    "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"<br>  ]<br>}</pre> | no |
| runner\_ami\_owners | The list of owners used to select the AMI of Gitlab runner docker-machine instances. | `list(string)` | <pre>[<br>  "099720109477"<br>]</pre> | no |
| runner\_iam\_policy\_arns | List of policy ARNs to be added to the instance profile of the gitlab runner agent ec2 instance. | `list(string)` | `[]` | no |
| runner\_instance\_ebs\_optimized | Enable the GitLab runner instance to be EBS-optimized. | `bool` | `true` | no |
| runner\_instance\_enable\_monitoring | Enable the GitLab runner instance to have detailed monitoring. | `bool` | `true` | no |
| runner\_instance\_spot\_price | By setting a spot price bid price the runner agent will be created via a spot request. Be aware that spot instances can be stopped by AWS. | `string` | `null` | no |
| runner\_root\_block\_device | The EC2 instance root block device configuration. Takes the following keys: `delete_on_termination`, `volume_type`, `volume_size`, `encrypted`, `iops` | `map(string)` | `{}` | no |
| runner\_tags | Map of tags that will be added to runner EC2 instances. | `map(string)` | `{}` | no |
| runners\_additional\_volumes | Additional volumes that will be used in the runner config.toml, e.g Docker socket | `list(any)` | `[]` | no |
| runners\_concurrent | Concurrent value for the runners, will be used in the runner config.toml. | `number` | `10` | no |
| runners\_docker\_runtime | docker runtime for runners, will be used in the runner config.toml | `string` | `""` | no |
| runners\_ebs\_optimized | Enable runners to be EBS-optimized. | `bool` | `true` | no |
| runners\_environment\_vars | Environment variables during build execution, e.g. KEY=Value, see runner-public example. Will be used in the runner config.toml | `list(string)` | `[]` | no |
| runners\_executor | The executor to use. Currently supports `docker+machine` or `docker`. | `string` | `"docker+machine"` | no |
| runners\_gitlab\_url | URL of the GitLab instance to connect to. | `string` | n/a | yes |
| runners\_helper\_image | Overrides the default helper image used to clone repos and upload artifacts, will be used in the runner config.toml | `string` | `""` | no |
| runners\_iam\_instance\_profile\_name | IAM instance profile name of the runners, will be used in the runner config.toml | `string` | `""` | no |
| runners\_idle\_count | Idle count of the runners, will be used in the runner config.toml. | `number` | `0` | no |
| runners\_idle\_time | Idle time of the runners, will be used in the runner config.toml. | `number` | `600` | no |
| runners\_image | Image to run builds, will be used in the runner config.toml | `string` | `"docker:18.03.1-ce"` | no |
| runners\_install\_amazon\_ecr\_credential\_helper | Install amazon-ecr-credential-helper inside `userdata_pre_install` script | `bool` | `false` | no |
| runners\_limit | Limit for the runners, will be used in the runner config.toml. | `number` | `0` | no |
| runners\_machine\_autoscaling | Set autoscaling parameters based on periods, see https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runnersmachine-section | <pre>list(object({<br>    periods    = list(string)<br>    idle_count = number<br>    idle_time  = number<br>    timezone   = string<br>  }))</pre> | `[]` | no |
| runners\_max\_builds | Max builds for each runner after which it will be removed, will be used in the runner config.toml. By default set to 0, no maxBuilds will be set in the configuration. | `number` | `0` | no |
| runners\_monitoring | Enable detailed cloudwatch monitoring for spot instances. | `bool` | `false` | no |
| runners\_name | Name of the runner, will be used in the runner config.toml. | `string` | n/a | yes |
| runners\_off\_peak\_idle\_count | Deprecated, please use `runners_machine_autoscaling`. Off peak idle count of the runners, will be used in the runner config.toml. | `number` | `-1` | no |
| runners\_off\_peak\_idle\_time | Deprecated, please use `runners_machine_autoscaling`. Off peak idle time of the runners, will be used in the runner config.toml. | `number` | `-1` | no |
| runners\_off\_peak\_periods | Deprecated, please use `runners_machine_autoscaling`. Off peak periods of the runners, will be used in the runner config.toml. | `string` | `null` | no |
| runners\_off\_peak\_timezone | Deprecated, please use `runners_machine_autoscaling`. Off peak idle time zone of the runners, will be used in the runner config.toml. | `string` | `null` | no |
| runners\_output\_limit | Sets the maximum build log size in kilobytes, by default set to 4096 (4MB) | `number` | `4096` | no |
| runners\_post\_build\_script | Commands to be executed on the Runner just after executing the build, but before executing after\_script. | `string` | `"\"\""` | no |
| runners\_pre\_build\_script | Script to execute in the pipeline just before the build, will be used in the runner config.toml | `string` | `"\"\""` | no |
| runners\_pre\_clone\_script | Commands to be executed on the Runner before cloning the Git repository. this can be used to adjust the Git client configuration first, for example. | `string` | `"\"\""` | no |
| runners\_privileged | Runners will run in privileged mode, will be used in the runner config.toml | `bool` | `true` | no |
| runners\_pull\_policy | pull\_policy for the runners, will be used in the runner config.toml | `string` | `"always"` | no |
| runners\_request\_concurrency | Limit number of concurrent requests for new jobs from GitLab (default 1) | `number` | `1` | no |
| runners\_request\_spot\_instance | Whether or not to request spot instances via docker-machine | `bool` | `true` | no |
| runners\_root\_size | Runner instance root size in GB. | `number` | `16` | no |
| runners\_services\_volumes\_tmpfs | n/a | <pre>list(object({<br>    volume  = string<br>    options = string<br>  }))</pre> | `[]` | no |
| runners\_shm\_size | shm\_size for the runners, will be used in the runner config.toml | `number` | `0` | no |
| runners\_token | Token for the runner, will be used in the runner config.toml. | `string` | `"__REPLACED_BY_USER_DATA__"` | no |
| runners\_use\_private\_address | Restrict runners to the use of a private IP address | `bool` | `true` | no |
| runners\_volumes\_tmpfs | n/a | <pre>list(object({<br>    volume  = string<br>    options = string<br>  }))</pre> | `[]` | no |
| schedule\_config | Map containing the configuration of the ASG scale-in and scale-up for the runner instance. Will only be used if enable\_schedule is set to true. | `map(any)` | <pre>{<br>  "scale_in_count": 0,<br>  "scale_in_recurrence": "0 18 * * 1-5",<br>  "scale_out_count": 1,<br>  "scale_out_recurrence": "0 8 * * 1-5"<br>}</pre> | no |
| secure\_parameter\_store\_runner\_token\_key | The key name used store the Gitlab runner token in Secure Parameter Store | `string` | `"runner-token"` | no |
| ssh\_key\_pair | Set this to use existing AWS key pair | `string` | `null` | no |
| subnet\_id\_runners | List of subnets used for hosting the gitlab-runners. | `string` | n/a | yes |
| subnet\_ids\_gitlab\_runner | Subnet used for hosting the GitLab runner. | `list(string)` | n/a | yes |
| tags | Map of tags that will be added to created resources. By default resources will be tagged with name and environment. | `map(string)` | `{}` | no |
| userdata\_post\_install | User-data script snippet to insert after GitLab runner install | `string` | `""` | no |
| userdata\_pre\_install | User-data script snippet to insert before GitLab runner install | `string` | `""` | no |
| vpc\_id | The target VPC for the docker-machine and runner instances. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| runner\_agent\_role\_arn | ARN of the role used for the ec2 instance for the GitLab runner agent. |
| runner\_agent\_role\_name | Name of the role used for the ec2 instance for the GitLab runner agent. |
| runner\_agent\_sg\_id | ID of the security group attached to the GitLab runner agent. |
| runner\_as\_group\_name | Name of the autoscaling group for the gitlab-runner instance |
| runner\_cache\_bucket\_arn | ARN of the S3 for the build cache. |
| runner\_cache\_bucket\_name | Name of the S3 for the build cache. |
| runner\_eip | EIP of the Gitlab Runner |
| runner\_role\_arn | ARN of the role used for the docker machine runners. |
| runner\_role\_name | Name of the role used for the docker machine runners. |
| runner\_sg\_id | ID of the security group attached to the docker machine runners. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Contributors ✨

This project exists thanks to all the people who contribute.

<a href="https://github.com/npalm/terraform-aws-gitlab-runner/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=npalm/terraform-aws-gitlab-runner" />
</a>

Made with [contributors-img](https://contrib.rocks).

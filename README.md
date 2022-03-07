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
  name_iam_objects = "gitlab-runner"
}

//this doesn't work
agent_tags = merge(local.my_tags, map("Name", "Gitlab Runner Agent"))
```

The runner supports 3 main scenarios:

### GitLab CI docker-machine runner - one runner agent

In this scenario the runner agent is running on a single EC2 node and runners are created by [docker machine](https://docs.gitlab.com/runner/configuration/autoscale.html) using spot instances. Runners will scale automatically based on the configuration. The module creates a S3 cache by default, which is shared across runners (spot instances).

![runners-default](https://github.com/npalm/assets/raw/main/images/terraform-aws-gitlab-runner/runner-default.png)

### GitLab CI docker-machine runner - multiple runner agents

In this scenario the multiple runner agents can be created with different configuration by instantiating the module multiple times. Runners will scale automatically based on the configuration. The S3 cache can be shared across runners by managing the cache outside of the module.

![runners-cache](https://github.com/npalm/assets/raw/main/images/terraform-aws-gitlab-runner/runner-cache.png)

### GitLab Ci docker runner

In this scenario _not_ docker machine is used but docker to schedule the builds. Builds will run on the same EC2 instance as the agent. No auto scaling is supported.

![runners-docker](https://github.com/npalm/assets/raw/main/images/terraform-aws-gitlab-runner/runner-docker.png)

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

### Auto Scaling Group Instance Termination

The Auto Scaling Group may be configured with a
[lifecycle hook](https://docs.aws.amazon.com/autoscaling/ec2/userguide/lifecycle-hooks.html)
that executes a provided Lambda function when the runner is terminated to
terminate additional instances that were spawned.

The use of the termination lifecycle can be toggled using the
`asg_termination_lifecycle_hook_create` variable.

When using this feature, a `builds/` directory relative to the root module will
persist that contains the packaged Lambda function.

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

### Scenario: Basic usage

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

### Removing the module

Remove the module from your Terraform code and deregister the runner manually from your Gitlab instance.
### Scenario: Multi-region deployment

Name clashes due to multi-region deployments for global AWS ressources create by this module (IAM, S3) can be avoided by including a distinguishing region specific prefix via the _cache_bucket_prefix_ string respectively via _name_iam_objects_ in the _overrides_ map. A simple example for this would be to set _region-specific-prefix_ to the AWS region the module is deployed to.



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

  overrides = {
    name_iam_objects = "<region-specific-prefix>-gitlab-runner-iam"
  }

  cache_bucket_prefix = "<region-specific-prefix>"
}
```

## Examples

A few [examples](https://github.com/npalm/terraform-aws-gitlab-runner/tree/develop/examples/) are provided. Use the following steps to deploy. Ensure your AWS and Terraform environment is set up correctly. All commands below should be run from the `terraform-aws-gitlab-runner/examples/<example-dir>` directory. Don't forget to remove the runners manually from your Gitlab instance as soon as your are done.

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
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.15.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3.35 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 3.35 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cache"></a> [cache](#module\_cache) | ./modules/cache | n/a |
| <a name="module_terminate_instances_lifecycle_function"></a> [terminate\_instances\_lifecycle\_function](#module\_terminate\_instances\_lifecycle\_function) | ./modules/terminate-instances | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.gitlab_runner_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_autoscaling_schedule.scale_in](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_schedule) | resource |
| [aws_autoscaling_schedule.scale_out](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_schedule) | resource |
| [aws_cloudwatch_log_group.environment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_eip.gitlab_runner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_iam_instance_profile.docker_machine](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_instance_profile.instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_policy.eip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.instance_docker_machine_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.instance_session_manager_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.service_linked_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.docker_machine](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.docker_machine_cache_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.docker_machine_session_manager_aws_managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.docker_machine_user_defined_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.eip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.instance_docker_machine_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.instance_session_manager_aws_managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.instance_session_manager_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.service_linked_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.user_defined_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kms_alias.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_launch_template.gitlab_runner_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_security_group.docker_machine](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.runner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.docker_machine_docker_runner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.docker_machine_docker_self](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.docker_machine_ping_runner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.docker_machine_ping_self](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.docker_machine_ssh_runner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.docker_machine_ssh_self](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.runner_ping_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_ssm_parameter.runner_registration_token](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.runner_sentry_dsn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ami.docker-machine](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_ami.runner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_availability_zone.runners](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zone) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_subnet.runners](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_agent_tags"></a> [agent\_tags](#input\_agent\_tags) | Map of tags that will be added to agent EC2 instances. | `map(string)` | `{}` | no |
| <a name="input_allow_iam_service_linked_role_creation"></a> [allow\_iam\_service\_linked\_role\_creation](#input\_allow\_iam\_service\_linked\_role\_creation) | Boolean used to control attaching the policy to a runner instance to create service linked roles. | `bool` | `true` | no |
| <a name="input_ami_filter"></a> [ami\_filter](#input\_ami\_filter) | List of maps used to create the AMI filter for the Gitlab runner agent AMI. Must resolve to an Amazon Linux 1 or 2 image. | `map(list(string))` | <pre>{<br>  "name": [<br>    "amzn2-ami-hvm-2.*-x86_64-ebs"<br>  ]<br>}</pre> | no |
| <a name="input_ami_owners"></a> [ami\_owners](#input\_ami\_owners) | The list of owners used to select the AMI of Gitlab runner agent instances. | `list(string)` | <pre>[<br>  "amazon"<br>]</pre> | no |
| <a name="input_arn_format"></a> [arn\_format](#input\_arn\_format) | ARN format to be used. May be changed to support deployment in GovCloud/China regions. | `string` | `"arn:aws"` | no |
| <a name="input_asg_delete_timeout"></a> [asg\_delete\_timeout](#input\_asg\_delete\_timeout) | Timeout when trying to delete the Runner ASG. | `string` | `"10m"` | no |
| <a name="input_asg_max_instance_lifetime"></a> [asg\_max\_instance\_lifetime](#input\_asg\_max\_instance\_lifetime) | The seconds before an instance is refreshed in the ASG. | `number` | `null` | no |
| <a name="input_asg_terminate_lifecycle_hook_create"></a> [asg\_terminate\_lifecycle\_hook\_create](#input\_asg\_terminate\_lifecycle\_hook\_create) | Boolean toggling the creation of the ASG instance terminate lifecycle hook. | `bool` | `true` | no |
| <a name="input_asg_terminate_lifecycle_hook_heartbeat_timeout"></a> [asg\_terminate\_lifecycle\_hook\_heartbeat\_timeout](#input\_asg\_terminate\_lifecycle\_hook\_heartbeat\_timeout) | The amount of time, in seconds, for the instances to remain in wait state. | `number` | `90` | no |
| <a name="input_asg_terminate_lifecycle_hook_name"></a> [asg\_terminate\_lifecycle\_hook\_name](#input\_asg\_terminate\_lifecycle\_hook\_name) | Specifies a custom name for the ASG terminate lifecycle hook and related resources. | `string` | `null` | no |
| <a name="input_asg_terminate_lifecycle_lambda_memory_size"></a> [asg\_terminate\_lifecycle\_lambda\_memory\_size](#input\_asg\_terminate\_lifecycle\_lambda\_memory\_size) | The memory size in MB to allocate to the terminate-instances Lambda function. | `number` | `128` | no |
| <a name="input_asg_terminate_lifecycle_lambda_timeout"></a> [asg\_terminate\_lifecycle\_lambda\_timeout](#input\_asg\_terminate\_lifecycle\_lambda\_timeout) | Amount of time the terminate-instances Lambda Function has to run in seconds. | `number` | `30` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region. | `string` | n/a | yes |
| <a name="input_cache_bucket"></a> [cache\_bucket](#input\_cache\_bucket) | Configuration to control the creation of the cache bucket. By default the bucket will be created and used as shared cache. To use the same cache across multiple runners disable the creation of the cache and provide a policy and bucket name. See the public runner example for more details. | `map(any)` | <pre>{<br>  "bucket": "",<br>  "create": true,<br>  "policy": ""<br>}</pre> | no |
| <a name="input_cache_bucket_name_include_account_id"></a> [cache\_bucket\_name\_include\_account\_id](#input\_cache\_bucket\_name\_include\_account\_id) | Boolean to add current account ID to cache bucket name. | `bool` | `true` | no |
| <a name="input_cache_bucket_prefix"></a> [cache\_bucket\_prefix](#input\_cache\_bucket\_prefix) | Prefix for s3 cache bucket name. | `string` | `""` | no |
| <a name="input_cache_bucket_set_random_suffix"></a> [cache\_bucket\_set\_random\_suffix](#input\_cache\_bucket\_set\_random\_suffix) | Append the cache bucket name with a random string suffix | `bool` | `false` | no |
| <a name="input_cache_bucket_versioning"></a> [cache\_bucket\_versioning](#input\_cache\_bucket\_versioning) | Boolean used to enable versioning on the cache bucket, false by default. | `bool` | `false` | no |
| <a name="input_cache_expiration_days"></a> [cache\_expiration\_days](#input\_cache\_expiration\_days) | Number of days before cache objects expires. | `number` | `1` | no |
| <a name="input_cache_shared"></a> [cache\_shared](#input\_cache\_shared) | Enables cache sharing between runners, false by default. | `bool` | `false` | no |
| <a name="input_cloudwatch_logging_retention_in_days"></a> [cloudwatch\_logging\_retention\_in\_days](#input\_cloudwatch\_logging\_retention\_in\_days) | Retention for cloudwatch logs. Defaults to unlimited | `number` | `0` | no |
| <a name="input_docker_machine_download_url"></a> [docker\_machine\_download\_url](#input\_docker\_machine\_download\_url) | (Optional) By default the module will use `docker_machine_version` to download the GitLab mantained version of Docker Machien. Alternative you can set this property to download location of the distribution of for the OS. See also https://docs.gitlab.com/runner/executors/docker_machine.html#install | `string` | `""` | no |
| <a name="input_docker_machine_egress_rules"></a> [docker\_machine\_egress\_rules](#input\_docker\_machine\_egress\_rules) | List of egress rules for the docker-machine instance(s). | <pre>list(object({<br>    cidr_blocks      = list(string)<br>    ipv6_cidr_blocks = list(string)<br>    prefix_list_ids  = list(string)<br>    from_port        = number<br>    protocol         = string<br>    security_groups  = list(string)<br>    self             = bool<br>    to_port          = number<br>    description      = string<br>  }))</pre> | <pre>[<br>  {<br>    "cidr_blocks": [<br>      "0.0.0.0/0"<br>    ],<br>    "description": "Allow all egress traffic for docker machine build runners",<br>    "from_port": 0,<br>    "ipv6_cidr_blocks": [<br>      "::/0"<br>    ],<br>    "prefix_list_ids": null,<br>    "protocol": "-1",<br>    "security_groups": null,<br>    "self": null,<br>    "to_port": 0<br>  }<br>]</pre> | no |
| <a name="input_docker_machine_iam_policy_arns"></a> [docker\_machine\_iam\_policy\_arns](#input\_docker\_machine\_iam\_policy\_arns) | List of policy ARNs to be added to the instance profile of the docker machine runners. | `list(string)` | `[]` | no |
| <a name="input_docker_machine_instance_type"></a> [docker\_machine\_instance\_type](#input\_docker\_machine\_instance\_type) | Instance type used for the instances hosting docker-machine. | `string` | `"m5.large"` | no |
| <a name="input_docker_machine_options"></a> [docker\_machine\_options](#input\_docker\_machine\_options) | List of additional options for the docker machine config. Each element of this list must be a key=value pair. E.g. '["amazonec2-zone=a"]' | `list(string)` | `[]` | no |
| <a name="input_docker_machine_role_json"></a> [docker\_machine\_role\_json](#input\_docker\_machine\_role\_json) | Docker machine runner instance override policy, expected to be in JSON format. | `string` | `""` | no |
| <a name="input_docker_machine_security_group_description"></a> [docker\_machine\_security\_group\_description](#input\_docker\_machine\_security\_group\_description) | A description for the docker-machine security group | `string` | `"A security group containing docker-machine instances"` | no |
| <a name="input_docker_machine_spot_price_bid"></a> [docker\_machine\_spot\_price\_bid](#input\_docker\_machine\_spot\_price\_bid) | Spot price bid. The maximum price willing to pay. By default the price is limited by the current on demand price for the instance type chosen. | `string` | `"on-demand-price"` | no |
| <a name="input_docker_machine_version"></a> [docker\_machine\_version](#input\_docker\_machine\_version) | By default docker\_machine\_download\_url is used to set the docker machine version. Version of docker-machine. The version will be ingored once `docker_machine_download_url` is set. | `string` | `"0.16.2-gitlab.12"` | no |
| <a name="input_enable_asg_recreation"></a> [enable\_asg\_recreation](#input\_enable\_asg\_recreation) | Enable automatic redeployment of the Runner ASG when the Launch Configs change. | `bool` | `true` | no |
| <a name="input_enable_cloudwatch_logging"></a> [enable\_cloudwatch\_logging](#input\_enable\_cloudwatch\_logging) | Boolean used to enable or disable the CloudWatch logging. | `bool` | `true` | no |
| <a name="input_enable_docker_machine_ssm_access"></a> [enable\_docker\_machine\_ssm\_access](#input\_enable\_docker\_machine\_ssm\_access) | Add IAM policies to the docker-machine instances to connect via the Session Manager. | `bool` | `false` | no |
| <a name="input_enable_eip"></a> [enable\_eip](#input\_enable\_eip) | Enable the assignment of an EIP to the gitlab runner instance | `bool` | `false` | no |
| <a name="input_enable_kms"></a> [enable\_kms](#input\_enable\_kms) | Let the module manage a KMS key, logs will be encrypted via KMS. Be-aware of the costs of an custom key. | `bool` | `false` | no |
| <a name="input_enable_manage_gitlab_token"></a> [enable\_manage\_gitlab\_token](#input\_enable\_manage\_gitlab\_token) | Boolean to enable the management of the GitLab token in SSM. If `true` the token will be stored in SSM, which means the SSM property is a terraform managed resource. If `false` the Gitlab token will be stored in the SSM by the user-data script during creation of the the instance. However the SSM parameter is not managed by terraform and will remain in SSM after a `terraform destroy`. | `bool` | `true` | no |
| <a name="input_enable_ping"></a> [enable\_ping](#input\_enable\_ping) | Allow ICMP Ping to the ec2 instances. | `bool` | `false` | no |
| <a name="input_enable_runner_ssm_access"></a> [enable\_runner\_ssm\_access](#input\_enable\_runner\_ssm\_access) | Add IAM policies to the runner agent instance to connect via the Session Manager. | `bool` | `false` | no |
| <a name="input_enable_runner_user_data_trace_log"></a> [enable\_runner\_user\_data\_trace\_log](#input\_enable\_runner\_user\_data\_trace\_log) | Enable bash xtrace for the user data script that creates the EC2 instance for the runner agent. Be aware this could log sensitive data such as you GitLab runner token. | `bool` | `false` | no |
| <a name="input_enable_schedule"></a> [enable\_schedule](#input\_enable\_schedule) | Flag used to enable/disable auto scaling group schedule for the runner instance. | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | A name that identifies the environment, used as prefix and for tagging. | `string` | n/a | yes |
| <a name="input_extra_security_group_ids_runner_agent"></a> [extra\_security\_group\_ids\_runner\_agent](#input\_extra\_security\_group\_ids\_runner\_agent) | Optional IDs of extra security groups to apply to the runner agent. This will not apply to the runners spun up when using the docker+machine executor, which is the default. | `list(string)` | `[]` | no |
| <a name="input_gitlab_runner_egress_rules"></a> [gitlab\_runner\_egress\_rules](#input\_gitlab\_runner\_egress\_rules) | List of egress rules for the gitlab runner instance. | <pre>list(object({<br>    cidr_blocks      = list(string)<br>    ipv6_cidr_blocks = list(string)<br>    prefix_list_ids  = list(string)<br>    from_port        = number<br>    protocol         = string<br>    security_groups  = list(string)<br>    self             = bool<br>    to_port          = number<br>    description      = string<br>  }))</pre> | <pre>[<br>  {<br>    "cidr_blocks": [<br>      "0.0.0.0/0"<br>    ],<br>    "description": null,<br>    "from_port": 0,<br>    "ipv6_cidr_blocks": [<br>      "::/0"<br>    ],<br>    "prefix_list_ids": null,<br>    "protocol": "-1",<br>    "security_groups": null,<br>    "self": null,<br>    "to_port": 0<br>  }<br>]</pre> | no |
| <a name="input_gitlab_runner_registration_config"></a> [gitlab\_runner\_registration\_config](#input\_gitlab\_runner\_registration\_config) | Configuration used to register the runner. See the README for an example, or reference the examples in the examples directory of this repo. | `map(string)` | <pre>{<br>  "access_level": "",<br>  "description": "",<br>  "locked_to_project": "",<br>  "maximum_timeout": "",<br>  "registration_token": "",<br>  "run_untagged": "",<br>  "tag_list": ""<br>}</pre> | no |
| <a name="input_gitlab_runner_security_group_description"></a> [gitlab\_runner\_security\_group\_description](#input\_gitlab\_runner\_security\_group\_description) | A description for the gitlab-runner security group | `string` | `"A security group containing gitlab-runner agent instances"` | no |
| <a name="input_gitlab_runner_security_group_ids"></a> [gitlab\_runner\_security\_group\_ids](#input\_gitlab\_runner\_security\_group\_ids) | A list of security group ids that are allowed to access the gitlab runner agent | `list(string)` | `[]` | no |
| <a name="input_gitlab_runner_version"></a> [gitlab\_runner\_version](#input\_gitlab\_runner\_version) | Version of the [GitLab runner](https://gitlab.com/gitlab-org/gitlab-runner/-/releases). | `string` | `"14.8.2"` | no |
| <a name="input_instance_role_json"></a> [instance\_role\_json](#input\_instance\_role\_json) | Default runner instance override policy, expected to be in JSON format. | `string` | `""` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Instance type used for the GitLab runner. | `string` | `"t3.micro"` | no |
| <a name="input_kms_alias_name"></a> [kms\_alias\_name](#input\_kms\_alias\_name) | Alias added to the kms\_key (if created and not provided by kms\_key\_id) | `string` | `""` | no |
| <a name="input_kms_deletion_window_in_days"></a> [kms\_deletion\_window\_in\_days](#input\_kms\_deletion\_window\_in\_days) | Key rotation window, set to 0 for no rotation. Only used when `enable_kms` is set to `true`. | `number` | `7` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | KMS key id to encrypted the CloudWatch logs. Ensure CloudWatch has access to the provided KMS key. | `string` | `""` | no |
| <a name="input_log_group_name"></a> [log\_group\_name](#input\_log\_group\_name) | Option to override the default name (`environment`) of the log group, requires `enable_cloudwatch_logging = true`. | `string` | `null` | no |
| <a name="input_metrics_autoscaling"></a> [metrics\_autoscaling](#input\_metrics\_autoscaling) | A list of metrics to collect. The allowed values are GroupDesiredCapacity, GroupInServiceCapacity, GroupPendingCapacity, GroupMinSize, GroupMaxSize, GroupInServiceInstances, GroupPendingInstances, GroupStandbyInstances, GroupStandbyCapacity, GroupTerminatingCapacity, GroupTerminatingInstances, GroupTotalCapacity, GroupTotalInstances. | `list(string)` | `null` | no |
| <a name="input_overrides"></a> [overrides](#input\_overrides) | This map provides the possibility to override some defaults. <br>The following attributes are supported: <br>  * `name_sg` set the name prefix and overwrite the `Name` tag for all security groups created by this module. <br>  * `name_runner_agent_instance` set the name prefix and override the `Name` tag for the EC2 gitlab runner instances defined in the auto launch configuration. <br>  * `name_docker_machine_runners` override the `Name` tag of EC2 instances created by the runner agent. <br>  * `name_iam_objects` set the name prefix of all AWS IAM resources created by this module. | `map(string)` | <pre>{<br>  "name_docker_machine_runners": "",<br>  "name_iam_objects": "",<br>  "name_runner_agent_instance": "",<br>  "name_sg": ""<br>}</pre> | no |
| <a name="input_permissions_boundary"></a> [permissions\_boundary](#input\_permissions\_boundary) | Name of permissions boundary policy to attach to AWS IAM roles | `string` | `""` | no |
| <a name="input_role_tags"></a> [role\_tags](#input\_role\_tags) | Map of tags that will be added to the role created. Useful for tag based authorization. | `map(string)` | `{}` | no |
| <a name="input_runner_agent_uses_private_address"></a> [runner\_agent\_uses\_private\_address](#input\_runner\_agent\_uses\_private\_address) | Restrict the runner agent to the use of a private IP address. If `runner_agent_uses_private_address` is set to `false` it will override the `runners_use_private_address` for the agent. | `bool` | `true` | no |
| <a name="input_runner_ami_filter"></a> [runner\_ami\_filter](#input\_runner\_ami\_filter) | List of maps used to create the AMI filter for the Gitlab runner docker-machine AMI. | `map(list(string))` | <pre>{<br>  "name": [<br>    "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"<br>  ]<br>}</pre> | no |
| <a name="input_runner_ami_owners"></a> [runner\_ami\_owners](#input\_runner\_ami\_owners) | The list of owners used to select the AMI of Gitlab runner docker-machine instances. | `list(string)` | <pre>[<br>  "099720109477"<br>]</pre> | no |
| <a name="input_runner_iam_policy_arns"></a> [runner\_iam\_policy\_arns](#input\_runner\_iam\_policy\_arns) | List of policy ARNs to be added to the instance profile of the gitlab runner agent ec2 instance. | `list(string)` | `[]` | no |
| <a name="input_runner_instance_ebs_optimized"></a> [runner\_instance\_ebs\_optimized](#input\_runner\_instance\_ebs\_optimized) | Enable the GitLab runner instance to be EBS-optimized. | `bool` | `true` | no |
| <a name="input_runner_instance_enable_monitoring"></a> [runner\_instance\_enable\_monitoring](#input\_runner\_instance\_enable\_monitoring) | Enable the GitLab runner instance to have detailed monitoring. | `bool` | `true` | no |
| <a name="input_runner_instance_metadata_options_http_endpoint"></a> [runner\_instance\_metadata\_options\_http\_endpoint](#input\_runner\_instance\_metadata\_options\_http\_endpoint) | Enable the Gitlab runner agent instance metadata service. The allowed values are enabled, disabled. | `string` | `"enabled"` | no |
| <a name="input_runner_instance_metadata_options_http_tokens"></a> [runner\_instance\_metadata\_options\_http\_tokens](#input\_runner\_instance\_metadata\_options\_http\_tokens) | Set if Gitlab runner agent instance metadata service session tokens are required. The allowed values are optional, required. | `string` | `"optional"` | no |
| <a name="input_runner_instance_spot_price"></a> [runner\_instance\_spot\_price](#input\_runner\_instance\_spot\_price) | By setting a spot price bid price the runner agent will be created via a spot request. Be aware that spot instances can be stopped by AWS. Choose "on-demand-price" to pay up to the current on demand price for the instance type chosen. | `string` | `null` | no |
| <a name="input_runner_root_block_device"></a> [runner\_root\_block\_device](#input\_runner\_root\_block\_device) | The EC2 instance root block device configuration. Takes the following keys: `device_name`, `delete_on_termination`, `volume_type`, `volume_size`, `encrypted`, `iops`, `throughput`, `kms_key_id` | `map(string)` | `{}` | no |
| <a name="input_runner_tags"></a> [runner\_tags](#input\_runner\_tags) | Map of tags that will be added to runner EC2 instances. | `map(string)` | `{}` | no |
| <a name="input_runners_add_dind_volumes"></a> [runners\_add\_dind\_volumes](#input\_runners\_add\_dind\_volumes) | Add certificates and docker.sock to the volumes to support docker-in-docker (dind) | `bool` | `false` | no |
| <a name="input_runners_additional_volumes"></a> [runners\_additional\_volumes](#input\_runners\_additional\_volumes) | Additional volumes that will be used in the runner config.toml, e.g Docker socket | `list(any)` | `[]` | no |
| <a name="input_runners_check_interval"></a> [runners\_check\_interval](#input\_runners\_check\_interval) | defines the interval length, in seconds, between new jobs check. | `number` | `3` | no |
| <a name="input_runners_concurrent"></a> [runners\_concurrent](#input\_runners\_concurrent) | Concurrent value for the runners, will be used in the runner config.toml. | `number` | `10` | no |
| <a name="input_runners_disable_cache"></a> [runners\_disable\_cache](#input\_runners\_disable\_cache) | Runners will not use local cache, will be used in the runner config.toml | `bool` | `false` | no |
| <a name="input_runners_docker_registry_mirror"></a> [runners\_docker\_registry\_mirror](#input\_runners\_docker\_registry\_mirror) | The docker registry mirror to use to avoid rate limiting by hub.docker.com | `string` | `""` | no |
| <a name="input_runners_docker_runtime"></a> [runners\_docker\_runtime](#input\_runners\_docker\_runtime) | docker runtime for runners, will be used in the runner config.toml | `string` | `""` | no |
| <a name="input_runners_ebs_optimized"></a> [runners\_ebs\_optimized](#input\_runners\_ebs\_optimized) | Enable runners to be EBS-optimized. | `bool` | `true` | no |
| <a name="input_runners_environment_vars"></a> [runners\_environment\_vars](#input\_runners\_environment\_vars) | Environment variables during build execution, e.g. KEY=Value, see runner-public example. Will be used in the runner config.toml | `list(string)` | `[]` | no |
| <a name="input_runners_executor"></a> [runners\_executor](#input\_runners\_executor) | The executor to use. Currently supports `docker+machine` or `docker`. | `string` | `"docker+machine"` | no |
| <a name="input_runners_gitlab_url"></a> [runners\_gitlab\_url](#input\_runners\_gitlab\_url) | URL of the GitLab instance to connect to. | `string` | n/a | yes |
| <a name="input_runners_helper_image"></a> [runners\_helper\_image](#input\_runners\_helper\_image) | Overrides the default helper image used to clone repos and upload artifacts, will be used in the runner config.toml | `string` | `""` | no |
| <a name="input_runners_iam_instance_profile_name"></a> [runners\_iam\_instance\_profile\_name](#input\_runners\_iam\_instance\_profile\_name) | IAM instance profile name of the runners, will be used in the runner config.toml | `string` | `""` | no |
| <a name="input_runners_idle_count"></a> [runners\_idle\_count](#input\_runners\_idle\_count) | Idle count of the runners, will be used in the runner config.toml. | `number` | `0` | no |
| <a name="input_runners_idle_time"></a> [runners\_idle\_time](#input\_runners\_idle\_time) | Idle time of the runners, will be used in the runner config.toml. | `number` | `600` | no |
| <a name="input_runners_image"></a> [runners\_image](#input\_runners\_image) | Image to run builds, will be used in the runner config.toml | `string` | `"docker:18.03.1-ce"` | no |
| <a name="input_runners_install_amazon_ecr_credential_helper"></a> [runners\_install\_amazon\_ecr\_credential\_helper](#input\_runners\_install\_amazon\_ecr\_credential\_helper) | Install amazon-ecr-credential-helper inside `userdata_pre_install` script | `bool` | `false` | no |
| <a name="input_runners_limit"></a> [runners\_limit](#input\_runners\_limit) | Limit for the runners, will be used in the runner config.toml. | `number` | `0` | no |
| <a name="input_runners_machine_autoscaling"></a> [runners\_machine\_autoscaling](#input\_runners\_machine\_autoscaling) | Set autoscaling parameters based on periods, see https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runnersmachine-section | <pre>list(object({<br>    periods    = list(string)<br>    idle_count = number<br>    idle_time  = number<br>    timezone   = string<br>  }))</pre> | `[]` | no |
| <a name="input_runners_max_builds"></a> [runners\_max\_builds](#input\_runners\_max\_builds) | Max builds for each runner after which it will be removed, will be used in the runner config.toml. By default set to 0, no maxBuilds will be set in the configuration. | `number` | `0` | no |
| <a name="input_runners_monitoring"></a> [runners\_monitoring](#input\_runners\_monitoring) | Enable detailed cloudwatch monitoring for spot instances. | `bool` | `false` | no |
| <a name="input_runners_name"></a> [runners\_name](#input\_runners\_name) | Name of the runner, will be used in the runner config.toml. | `string` | n/a | yes |
| <a name="input_runners_output_limit"></a> [runners\_output\_limit](#input\_runners\_output\_limit) | Sets the maximum build log size in kilobytes, by default set to 4096 (4MB) | `number` | `4096` | no |
| <a name="input_runners_post_build_script"></a> [runners\_post\_build\_script](#input\_runners\_post\_build\_script) | Commands to be executed on the Runner just after executing the build, but before executing after\_script. | `string` | `"\"\""` | no |
| <a name="input_runners_pre_build_script"></a> [runners\_pre\_build\_script](#input\_runners\_pre\_build\_script) | Script to execute in the pipeline just before the build, will be used in the runner config.toml | `string` | `"\"\""` | no |
| <a name="input_runners_pre_clone_script"></a> [runners\_pre\_clone\_script](#input\_runners\_pre\_clone\_script) | Commands to be executed on the Runner before cloning the Git repository. this can be used to adjust the Git client configuration first, for example. | `string` | `"\"\""` | no |
| <a name="input_runners_privileged"></a> [runners\_privileged](#input\_runners\_privileged) | Runners will run in privileged mode, will be used in the runner config.toml | `bool` | `true` | no |
| <a name="input_runners_pull_policy"></a> [runners\_pull\_policy](#input\_runners\_pull\_policy) | pull\_policy for the runners, will be used in the runner config.toml | `string` | `"always"` | no |
| <a name="input_runners_request_concurrency"></a> [runners\_request\_concurrency](#input\_runners\_request\_concurrency) | Limit number of concurrent requests for new jobs from GitLab (default 1) | `number` | `1` | no |
| <a name="input_runners_request_spot_instance"></a> [runners\_request\_spot\_instance](#input\_runners\_request\_spot\_instance) | Whether or not to request spot instances via docker-machine | `bool` | `true` | no |
| <a name="input_runners_root_size"></a> [runners\_root\_size](#input\_runners\_root\_size) | Runner instance root size in GB. | `number` | `16` | no |
| <a name="input_runners_services_volumes_tmpfs"></a> [runners\_services\_volumes\_tmpfs](#input\_runners\_services\_volumes\_tmpfs) | n/a | <pre>list(object({<br>    volume  = string<br>    options = string<br>  }))</pre> | `[]` | no |
| <a name="input_runners_shm_size"></a> [runners\_shm\_size](#input\_runners\_shm\_size) | shm\_size for the runners, will be used in the runner config.toml | `number` | `0` | no |
| <a name="input_runners_token"></a> [runners\_token](#input\_runners\_token) | Token for the runner, will be used in the runner config.toml. | `string` | `"__REPLACED_BY_USER_DATA__"` | no |
| <a name="input_runners_use_private_address"></a> [runners\_use\_private\_address](#input\_runners\_use\_private\_address) | Restrict runners to the use of a private IP address. If `runner_agent_uses_private_address` is set to `true`(default), `runners_use_private_address` will also apply for the agent. | `bool` | `true` | no |
| <a name="input_runners_volumes_tmpfs"></a> [runners\_volumes\_tmpfs](#input\_runners\_volumes\_tmpfs) | n/a | <pre>list(object({<br>    volume  = string<br>    options = string<br>  }))</pre> | `[]` | no |
| <a name="input_schedule_config"></a> [schedule\_config](#input\_schedule\_config) | Map containing the configuration of the ASG scale-in and scale-up for the runner instance. Will only be used if enable\_schedule is set to true. | `map(any)` | <pre>{<br>  "scale_in_count": 0,<br>  "scale_in_recurrence": "0 18 * * 1-5",<br>  "scale_out_count": 1,<br>  "scale_out_recurrence": "0 8 * * 1-5"<br>}</pre> | no |
| <a name="input_secure_parameter_store_runner_sentry_dsn"></a> [secure\_parameter\_store\_runner\_sentry\_dsn](#input\_secure\_parameter\_store\_runner\_sentry\_dsn) | The Sentry DSN name used to store the Sentry DSN in Secure Parameter Store | `string` | `"sentry-dsn"` | no |
| <a name="input_secure_parameter_store_runner_token_key"></a> [secure\_parameter\_store\_runner\_token\_key](#input\_secure\_parameter\_store\_runner\_token\_key) | The key name used store the Gitlab runner token in Secure Parameter Store | `string` | `"runner-token"` | no |
| <a name="input_sentry_dsn"></a> [sentry\_dsn](#input\_sentry\_dsn) | Sentry DSN of the project for the runner to use (uses legacy DSN format) | `string` | `"__SENTRY_DSN_REPLACED_BY_USER_DATA__"` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Subnet id used for the runner and executors. Must belong to the VPC specified above. | `string` | `""` | no |
| <a name="input_subnet_id_runners"></a> [subnet\_id\_runners](#input\_subnet\_id\_runners) | Deprecated! Use subnet\_id instead. List of subnets used for hosting the gitlab-runners. | `string` | `""` | no |
| <a name="input_subnet_ids_gitlab_runner"></a> [subnet\_ids\_gitlab\_runner](#input\_subnet\_ids\_gitlab\_runner) | Deprecated! Use subnet\_id instead. Subnet used for hosting the GitLab runner. | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags that will be added to created resources. By default resources will be tagged with name and environment. | `map(string)` | `{}` | no |
| <a name="input_userdata_post_install"></a> [userdata\_post\_install](#input\_userdata\_post\_install) | User-data script snippet to insert after GitLab runner install | `string` | `""` | no |
| <a name="input_userdata_pre_install"></a> [userdata\_pre\_install](#input\_userdata\_pre\_install) | User-data script snippet to insert before GitLab runner install | `string` | `""` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The target VPC for the docker-machine and runner instances. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_runner_agent_role_arn"></a> [runner\_agent\_role\_arn](#output\_runner\_agent\_role\_arn) | ARN of the role used for the ec2 instance for the GitLab runner agent. |
| <a name="output_runner_agent_role_name"></a> [runner\_agent\_role\_name](#output\_runner\_agent\_role\_name) | Name of the role used for the ec2 instance for the GitLab runner agent. |
| <a name="output_runner_agent_sg_id"></a> [runner\_agent\_sg\_id](#output\_runner\_agent\_sg\_id) | ID of the security group attached to the GitLab runner agent. |
| <a name="output_runner_as_group_name"></a> [runner\_as\_group\_name](#output\_runner\_as\_group\_name) | Name of the autoscaling group for the gitlab-runner instance |
| <a name="output_runner_cache_bucket_arn"></a> [runner\_cache\_bucket\_arn](#output\_runner\_cache\_bucket\_arn) | ARN of the S3 for the build cache. |
| <a name="output_runner_cache_bucket_name"></a> [runner\_cache\_bucket\_name](#output\_runner\_cache\_bucket\_name) | Name of the S3 for the build cache. |
| <a name="output_runner_eip"></a> [runner\_eip](#output\_runner\_eip) | EIP of the Gitlab Runner |
| <a name="output_runner_launch_template_name"></a> [runner\_launch\_template\_name](#output\_runner\_launch\_template\_name) | The name of the runner's launch template. |
| <a name="output_runner_role_arn"></a> [runner\_role\_arn](#output\_runner\_role\_arn) | ARN of the role used for the docker machine runners. |
| <a name="output_runner_role_name"></a> [runner\_role\_name](#output\_runner\_role\_name) | Name of the role used for the docker machine runners. |
| <a name="output_runner_sg_id"></a> [runner\_sg\_id](#output\_runner\_sg\_id) | ID of the security group attached to the docker machine runners. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Contributors ✨

This project exists thanks to all the people who contribute.

<a href="https://github.com/npalm/terraform-aws-gitlab-runner/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=npalm/terraform-aws-gitlab-runner" />
</a>

Made with [contributors-img](https://contrib.rocks).

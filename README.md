<!-- First line should be a H1: Badges on top please! -->
<!-- markdownlint-disable MD041/first-line-heading/first-line-h1 -->
[![Terraform registry](https://img.shields.io/github/v/release/cattle-ops/terraform-aws-gitlab-runner?label=Terraform%20Registry)](https://registry.terraform.io/modules/cattle-ops/gitlab-runner/aws/)
[![Gitter](https://badges.gitter.im/terraform-aws-gitlab-runner/Lobby.svg)](https://gitter.im/terraform-aws-gitlab-runner/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)
[![Actions](https://github.com/cattle-ops/terraform-aws-gitlab-runner/workflows/CI/badge.svg)](https://github.com/cattle-ops/terraform-aws-gitlab-runner/actions)
[![Renovate][1]](https://www.mend.io/renovate/)
<!-- markdownlint-enable MD041/first-line-heading/first-line-h1 -->

# Terraform module for GitLab auto scaling runners on AWS spot instances <!-- omit in toc -->

- [The module](#the-module)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
- [Examples](#examples)
- [Contributors ✨](#contributors-) <!-- markdown-link-check-disable-line -->
- [Requirements](#requirements) <!-- markdown-link-check-disable-line -->
- [Providers](#providers) <!-- markdown-link-check-disable-line -->
- [Modules](#modules) <!-- markdown-link-check-disable-line -->
- [Resources](#resources) <!-- markdown-link-check-disable-line -->
- [Inputs](#inputs) <!-- markdown-link-check-disable-line -->
- [Outputs](#outputs) <!-- markdown-link-check-disable-line -->
- 
## The module

This [Terraform](https://www.terraform.io/) modules creates a [GitLab CI runner](https://docs.gitlab.com/runner/). A blog post
describes the original version of the runner. See the post at [040code](https://040code.github.io/2017/12/09/runners-on-the-spot/).
The original setup of the module is based on the blog post: [Auto scale GitLab CI runners and save 90% on EC2 costs](https://about.gitlab.com/2017/11/23/autoscale-ci-runners/).

> 💥 BREAKING CHANGE AHEAD: Version 7 of the module rewrites the whole variable section to
>    - harmonize the variable names
>    - harmonize the documentation
>    - remove deprecated variables
>    - gain a better overview of the features provided
>
> And it also adds
>   - all possible Docker settings
>   - the `idle_scale_factor`
>
> We know that this is a breaking change causing some pain, but we think it is worth it. We hope you agree. And to make the
> transition as smooth as possible, we have added a migration script to the `migrations` folder. It will cover almost all cases,
> but some minor rework might still be possible.
>
> Checkout [issue 819](https://github.com/cattle-ops/terraform-aws-gitlab-runner/issues/819)

The runners created by the module use spot instances by default for running the builds using the `docker+machine` executor.

- Shared cache in S3 with life cycle management to clear objects after x days.
- Logs streamed to CloudWatch.
- Runner agents registered automatically.

The name of the runner agent and runner is set with the overrides variable. Adding an agent runner name tag does not work.

```hcl
# ...
runner_instance = {
  name  = "Gitlab Runner connecting to GitLab"
}

# this doesn't work
agent_tags = merge(local.my_tags, map("Name", "Gitlab Runner connecting to GitLab"))
```

The runner supports 3 main scenarios:

### GitLab CI docker-machine runner - one runner agent

In this scenario the runner agent is running on a single EC2 node and runners are created by [docker machine](https://docs.gitlab.com/runner/configuration/autoscale.html)
using spot instances. Runners will scale automatically based on the configuration. The module creates a S3 cache by default,
which is shared across runners (spot instances).

![runners-default](https://github.com/cattle-ops/terraform-aws-gitlab-runner/raw/main/assets/images/runner-default.png)

### GitLab CI docker-machine runner - multiple runner agents

In this scenario the multiple runner agents can be created with different configuration by instantiating the module multiple times.
Runners will scale automatically based on the configuration. The S3 cache can be shared across runners by managing the cache
outside of the module.

![runners-cache](https://github.com/cattle-ops/terraform-aws-gitlab-runner/raw/main/assets/images/runner-cache.png)

### GitLab Ci docker runner

In this scenario _not_ docker machine is used but docker to schedule the builds. Builds will run on the same EC2 instance as the
agent. No auto scaling is supported.

![runners-docker](https://github.com/cattle-ops/terraform-aws-gitlab-runner/raw/main/assets/images/runner-docker.png)

## Prerequisites

### Terraform

Ensure you have Terraform installed. The modules is based on Terraform 0.11, see `.terraform-version` for the used version. A handy
tool to mange your Terraform version is [tfenv](https://github.com/kamatama41/tfenv).

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

In order to be able to destroy the module, you will need to run from a host with both `jq` and `aws` installed and accessible in
the environment.

On macOS it is simple to install them using `brew`.

```sh
brew install jq awscli
```

### Service linked roles

The GitLab runner EC2 instance requires the following service linked roles:

- AWSServiceRoleForAutoScaling
- AWSServiceRoleForEC2Spot

By default the EC2 instance is allowed to create the required roles, but this can be disabled by setting the option
`allow_iam_service_linked_role_creation` to `false`. If disabled you must ensure the roles exist. You can create them manually or
via Terraform.

```hcl
resource "aws_iam_service_linked_role" "spot" {
  aws_service_name = "spot.amazonaws.com"
}

resource "aws_iam_service_linked_role" "autoscaling" {
  aws_service_name = "autoscaling.amazonaws.com"
}
```

### KMS keys

If a KMS key is set via `kms_key_id`, make sure that you also give proper access to the key. Otherwise, you might
get errors, e.g. the build cache can't be decrypted or logging via CloudWatch is not possible. For a CloudWatch
example checkout [kms-policy.json](https://github.com/cattle-ops/terraform-aws-gitlab-runner/blob/main/policies/kms-policy.json)

### GitLab runner token configuration

By default the runner is registered on initial deployment. In previous versions of this module this was a manual process. The
manual process is still supported but will be removed in future releases. The runner token will be stored in the AWS SSM parameter
store. See [example](examples/runner-pre-registered/) for more details.

To register the runner automatically set the variable `gitlab_runner_registration_config["registration_token"]`. This token value
can be found in your GitLab project, group, or global settings. For a generic runner you can find the token in the admin section.
By default the runner will be locked to the target project, not run untagged. Below is an example of the configuration map.

```hcl
runner_gitlab_registration_config = {
  registration_token = "<registration token>"
  tag_list           = "<your tags, comma separated>"
  description        = "<some description>"
  locked_to_project  = "true"
  run_untagged       = "false"
  maximum_timeout    = "3600"
  # ref_protected runner will only run on pipelines triggered on protected branches. Defaults to not_protected
  access_level       = "<not_protected OR ref_protected>"
}
```

The registration token can also be read in via SSM parameter store. If no registration token is passed in, the module
will look up the token in the SSM parameter store at the location specified by `secure_parameter_store_gitlab_runner_registration_token_name`.

For migration to the new setup simply add the runner token to the parameter store. Once the runner is started it will lookup the
required values via the parameter store. If the value is `null` a new runner will be registered and a new token created/stored.

```sh
# set the following variables, look up the variables in your Terraform config.
# see your Terraform variables to fill in the vars below.
aws-region=<${var.aws_region}>
token=<runner-token-see-your-gitlab-runner>
parameter-name=<${var.environment}>-<${var.secure_parameter_store_runner_token_key}>

aws ssm put-parameter --overwrite --type SecureString  --name "${parameter-name}" --value ${token} --region "${aws-region}"
```

Once you have created the parameter, you must remove the variable `runners_token` from your config. The next time your GitLab
runner instance is created it will look up the token from the SSM parameter store.

Finally, the runner still supports the manual runner creation. No changes are required. Please keep in mind that this setup will be
removed in future releases.

### Auto Scaling Group

#### Scheduled scaling

When `enable_schedule=true`, the `schedule_config` variable can be used to scale the Auto Scaling group.

Scaling may be defined with one `scale_out` scheduled action and/or one `scale_in` scheduled action.

For example:

```hcl
  module "runner" {
    # ...
    runner_schedule_enable = true
    runner_schedule_config = {
      # Configure optional scale_out scheduled action
      scale_out_recurrence = "0 8 * * 1-5"
      scale_out_count      = 1 # Default for min_size, desired_capacity and max_size
      # Override using: scale_out_min_size, scale_out_desired_capacity, scale_out_max_size

      # Configure optional scale_in scheduled action
      scale_in_recurrence  = "0 18 * * 1-5"
      scale_in_count       = 0 # Default for min_size, desired_capacity and max_size
      # Override using: scale_out_min_size, scale_out_desired_capacity, scale_out_max_size
    }
  }
```

#### Instance Termination

The Auto Scaling Group may be configured with a [lifecycle hook](https://docs.aws.amazon.com/autoscaling/ec2/userguide/lifecycle-hooks.html)
that executes a provided Lambda function when the runner is terminated to terminate additional instances that were spawned.

The use of the termination lifecycle can be toggled using the `asg_termination_lifecycle_hook_create` variable.

When using this feature, a `builds/` directory relative to the root module will persist that contains the packaged Lambda function.

### Access runner instance

A few option are provided to access the runner instance:

1. Access via the Session Manager (SSM) by setting `enable_runner_ssm_access` to `true`. The policy to allow access via SSM is not
   very restrictive.
2. By setting none of the above, no keys or extra policies will be attached to the instance. You can still configure you own
   policies by attaching them to `runner_agent_role_arn`.

### GitLab runner cache

By default the module creates a cache for the runner in S3. Old objects are automatically removed via a configurable life cycle
policy on the bucket.

Creation of the bucket can be disabled and managed outside this module. A good use case is for sharing the cache across multiple
runners. For this purpose the cache is implemented as a sub module. For more details see the
[cache module](https://github.com/cattle-ops/terraform-aws-gitlab-runner/tree/main/modules/cache). An example implementation of
this use case can be found in the [runner-public](https://github.com/cattle-ops/terraform-aws-gitlab-runner/tree/main/examples/runner-public)
example.

In case you enable the access logging for the S3 cache bucket, you have to add the following statement to your S3 logging bucket
policy.

```json
{
    "Sid": "Allow access logging",
    "Effect": "Allow",
    "Principal": {
        "Service": "logging.s3.amazonaws.com"
    },
    "Action": "s3:PutObject",
    "Resource": "<s3-arn>/*"
}
```

In case you manage the S3 cache bucket yourself it might be necessary to apply the cache before applying the runner module. A
typical error message looks like:

```text
Error: Invalid count argument
on .terraform/modules/gitlab_runner/main.tf line 400, in resource "aws_iam_role_policy_attachment" "docker_machine_cache_instance":
  count = var.cache_bucket["create"] || length(lookup(var.cache_bucket, "policy", "")) > 0 ? 1 : 0
The "count" value depends on resource attributes that cannot be determined until apply, so Terraform cannot predict how many
instances will be created. To work around this, use the -target argument to first apply only the resources that the count
depends on.
```

The workaround is to use a `terraform apply -target=module.cache` followed by a `terraform apply` to apply everything else. This is
a one time effort needed at the very beginning.

## Usage

### Configuration

Update the variables in `terraform.tfvars` according to your needs and add the following variables. See the previous step for
instructions on how to obtain the token.

```hcl
runner_name  = "NAME_OF_YOUR_RUNNER"
gitlab_url   = "GITLAB_URL"
runner_token = "RUNNER_TOKEN"
```

The base image used to host the GitLab Runner agent is the latest available Amazon Linux 2 HVM EBS AMI. In previous versions of
this module a hard coded list of AMIs per region was provided. This list has been replaced by a search filter to find the latest
AMI. Setting the filter to `amzn2-ami-hvm-2.0.20200207.1-x86_64-ebs` will allow you to version lock the target AMI.

### Scenario: Basic usage

Below is a basic examples of usages of the module. Regarding the dependencies such as a VPC, have a look at the [default example](https://github.com/cattle-ops/terraform-aws-gitlab-runner/tree/main/examples/runner-default).

```hcl
module "runner" {
  # https://registry.terraform.io/modules/cattle-ops/gitlab-runner/aws/
  source  = "cattle-ops/gitlab-runner/aws"
   
  environment = "basic"

  vpc_id    = module.vpc.vpc_id
  subnet_id = element(module.vpc.private_subnets, 0)

   runner_gitlab = {
      url = "https://gitlab.com" 
   }

   runner_gitlab_registration_config = {
    registration_token = "my-token"
    tag_list           = "docker"
    description        = "runner default"
    locked_to_project  = "true"
    run_untagged       = "false"
    maximum_timeout    = "3600"
  }

   runner_worker_docker_machine_instance = {
      subnet_ids = module.vpc.private_subnets
   }
}
```

### Removing the module

As the module creates a number of resources during runtime (key pairs and spot instance requests), it needs a special
procedure to remove them.

1. Use the AWS Console to set the desired capacity of all auto scaling groups to 0. To find the correct ones use the
   `var.environment` as search criteria. Setting the desired capacity to 0 prevents AWS from creating new instances
   which will in turn create new resources.
2. Kill all agent ec2 instances on the via AWS Console. This triggers a Lambda function in the background which removes
   all resources created during runtime of the EC2 instances.
3. Wait 3 minutes so the Lambda function has enough time to delete the key pairs and spot instance requests.
4. Run a `terraform destroy` or `terraform apply` (depends on your setup) to remove the module.

If you don't follow the above procedure key pairs and spot instance requests might survive the removal and might cause
additional costs. But I have never seen that. You should also be fine by executing step 4 only.

### Scenario: Multi-region deployment

Name clashes due to multi-region deployments for global AWS resources create by this module (IAM, S3) can be avoided by including a
distinguishing region specific prefix via the _cache_bucket_prefix_ string respectively via _name_iam_objects_ in the _overrides_
map. A simple example for this would be to set _region-specific-prefix_ to the AWS region the module is deployed to.

```hcl
module "runner" {
   # https://registry.terraform.io/modules/cattle-ops/gitlab-runner/aws/
   source  = "cattle-ops/gitlab-runner/aws"

   environment = "multi-region-1"
   iam_object_prefix = "<region-specific-prefix>-gitlab-runner-iam"
   
   vpc_id    = module.vpc.vpc_id
   subnet_id = element(module.vpc.private_subnets, 0)

   runner_gitlab = {
      url = "https://gitlab.com"
   }

   runner_gitlab_registration_config = {
      registration_token = "my-token"
      tag_list           = "docker"
      description        = "runner default"
      locked_to_project  = "true"
      run_untagged       = "false"
      maximum_timeout    = "3600"
   }

   runner_worker_cache = {
      bucket_prefix = "<region-specific-prefix>"
   }
   
   runner_worker_docker_machine_instance = {
      subnet_ids = module.vpc.private_subnets
   }
}
```

### Scenario: Use of Spot Fleet

Since spot instances can be taken over by AWS depending on the instance type and AZ you are using, you may want multiple instances
types in multiple AZs. This is where spot fleets come in, when there is no capacity on one instance type and one AZ, AWS will take
the next instance type and so on. This update has been possible since the
[fork](https://gitlab.com/cki-project/docker-machine/-/tree/v0.16.2-gitlab.19-cki.2) of docker-machine supports spot fleets.

We have seen that the [fork](https://gitlab.com/cki-project/docker-machine/-/tree/v0.16.2-gitlab.19-cki.2) of docker-machine this
module is using consume more RAM using spot fleets. For comparison, if you launch 50 machines in the same time, it consumes
~1.2GB of RAM. In our case, we had to change the `instance_type` of the runner from `t3.micro` to `t3.small`.

#### Configuration example

```hcl
module "runner" {
   # https://registry.terraform.io/modules/cattle-ops/gitlab-runner/aws/
   source  = "cattle-ops/gitlab-runner/aws"

   environment = "spot-fleet"

   vpc_id    = module.vpc.vpc_id
   subnet_id = element(module.vpc.private_subnets, 0)

   runner_gitlab = {
      url = "https://gitlab.com"
   }

   runner_gitlab_registration_config = {
      registration_token = "my-token"
      tag_list           = "docker"
      description        = "runner default"
      locked_to_project  = "true"
      run_untagged       = "false"
      maximum_timeout    = "3600"
   }

   runner_worker = {
      type = "docker+machine"
   }

   runner_worker_docker_machine_fleet = {
      enable = true
   }
   
   runner_worker_docker_machine_instance = {
      types = ["t3a.medium", "t3.medium", "t2.medium"]
      subnet_ids = module.vpc.private_subnets
   }
}
```

## Examples

A few [examples](https://github.com/cattle-ops/terraform-aws-gitlab-runner/tree/main/examples/) are provided. Use the
following steps to deploy. Ensure your AWS and Terraform environment is set up correctly. All commands below should be
run from the `terraform-aws-gitlab-runner/examples/<example-dir>` directory. Don't forget to remove the runners
manually from your Gitlab instance as soon as your are done.

### Versions

The version of Terraform is locked down via tfenv, see the `.terraform-version` file for the expected versions.
Providers are locked down as well in the `providers.tf` file.

### Configure

The examples are configured with defaults that should work in general. The examples are in general configured for the
region Ireland `eu-west-1`. The only parameter that needs to be provided is the GitLab registration token. The token can be
found in GitLab in the runner section (global, group or repo scope). Create a file `terraform.tfvars` and the registration token.

```hcl
    registration_token = "MY_TOKEN"
```

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

## Contributors ✨

This project exists thanks to all the people who contribute.

<!-- this is the only option to integrate the contributors list in the README.md -->
<!-- markdownlint-disable MD033 -->
<a href="https://github.com/cattle-ops/terraform-aws-gitlab-runner/graphs/contributors">
  <!-- markdownlint-disable MD033 -->
  <img src="https://contrib.rocks/image?repo=cattle-ops/terraform-aws-gitlab-runner" />
</a>

Made with [contributors-img](https://contrib.rocks).

## Module Documentation

<!-- markdownlint-disable -->
<!-- cSpell:disable -->
<!-- markdown-link-check-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.4.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | >= 3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.49.0 |
| <a name="provider_local"></a> [local](#provider\_local) | 2.4.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | >= 3 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cache"></a> [cache](#module\_cache) | ./modules/cache | n/a |
| <a name="module_terminate_agent_hook"></a> [terminate\_agent\_hook](#module\_terminate\_agent\_hook) | ./modules/terminate-agent-hook | n/a |

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
| [aws_iam_policy.instance_kms_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
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
| [aws_iam_role_policy_attachment.instance_kms_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.instance_session_manager_aws_managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.instance_session_manager_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.service_linked_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.user_defined_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_key_pair.fleet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_kms_alias.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_launch_template.fleet_gitlab_runner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
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
| [local_file.config_toml](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.user_data](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [tls_private_key.fleet](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [aws_ami.docker-machine](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_ami.runner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_availability_zone.runners](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zone) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_subnet.runners](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_debug"></a> [debug](#input\_debug) | trace\_runner\_user\_data: Enable bash trace for the user data script on the Agent. Be aware this could log sensitive data such as you GitLab runner token.<br>write\_runner\_config\_to\_file: When enabled, outputs the rendered config.toml file in the root module. Note that enabling this can<br>                             potentially expose sensitive information.<br>write\_runner\_user\_data\_to\_file: When enabled, outputs the rendered userdata.sh file in the root module. Note that enabling this<br>                                can potentially expose sensitive information. | <pre>object({<br>    trace_runner_user_data         = optional(bool, false)<br>    write_runner_config_to_file    = optional(bool, false)<br>    write_runner_user_data_to_file = optional(bool, false)<br>  })</pre> | `{}` | no |
| <a name="input_enable_managed_kms_key"></a> [enable\_managed\_kms\_key](#input\_enable\_managed\_kms\_key) | Let the module manage a KMS key. Be-aware of the costs of an custom key. Do not specify a `kms_key_id` when `enable_kms` is set to `true`. | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | A name that identifies the environment, used as prefix and for tagging. | `string` | n/a | yes |
<<<<<<< HEAD
| <a name="input_extra_security_group_ids_runner_agent"></a> [extra\_security\_group\_ids\_runner\_agent](#input\_extra\_security\_group\_ids\_runner\_agent) | Optional IDs of extra security groups to apply to the runner agent. This will not apply to the runners spun up when using the docker+machine executor, which is the default. | `list(string)` | `[]` | no |
| <a name="input_gitlab_runner_egress_rules"></a> [gitlab\_runner\_egress\_rules](#input\_gitlab\_runner\_egress\_rules) | List of egress rules for the gitlab runner instance. | <pre>list(object({<br>    cidr_blocks      = list(string)<br>    ipv6_cidr_blocks = list(string)<br>    prefix_list_ids  = list(string)<br>    from_port        = number<br>    protocol         = string<br>    security_groups  = list(string)<br>    self             = bool<br>    to_port          = number<br>    description      = string<br>  }))</pre> | <pre>[<br>  {<br>    "cidr_blocks": [<br>      "0.0.0.0/0"<br>    ],<br>    "description": null,<br>    "from_port": 0,<br>    "ipv6_cidr_blocks": [<br>      "::/0"<br>    ],<br>    "prefix_list_ids": null,<br>    "protocol": "-1",<br>    "security_groups": null,<br>    "self": null,<br>    "to_port": 0<br>  }<br>]</pre> | no |
| <a name="input_gitlab_runner_registration_config"></a> [gitlab\_runner\_registration\_config](#input\_gitlab\_runner\_registration\_config) | Configuration used to register the runner. See the README for an example, or reference the examples in the examples directory of this repo. | `map(string)` | <pre>{<br>  "access_level": "",<br>  "description": "",<br>  "locked_to_project": "",<br>  "maximum_timeout": "",<br>  "registration_token": "",<br>  "run_untagged": "",<br>  "tag_list": ""<br>}</pre> | no |
| <a name="input_gitlab_runner_security_group_description"></a> [gitlab\_runner\_security\_group\_description](#input\_gitlab\_runner\_security\_group\_description) | A description for the gitlab-runner security group | `string` | `"A security group containing gitlab-runner agent instances"` | no |
| <a name="input_gitlab_runner_security_group_ids"></a> [gitlab\_runner\_security\_group\_ids](#input\_gitlab\_runner\_security\_group\_ids) | A list of security group ids that are allowed to access the gitlab runner agent | `list(string)` | `[]` | no |
| <a name="input_gitlab_runner_version"></a> [gitlab\_runner\_version](#input\_gitlab\_runner\_version) | Version of the [GitLab runner](https://gitlab.com/gitlab-org/gitlab-runner/-/releases). | `string` | `"15.3.0"` | no |
| <a name="input_instance_role_json"></a> [instance\_role\_json](#input\_instance\_role\_json) | Default runner instance override policy, expected to be in JSON format. | `string` | `""` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Instance type used for the GitLab runner. | `string` | `"t3.micro"` | no |
| <a name="input_kms_alias_name"></a> [kms\_alias\_name](#input\_kms\_alias\_name) | Alias added to the kms\_key (if created and not provided by kms\_key\_id) | `string` | `""` | no |
| <a name="input_kms_deletion_window_in_days"></a> [kms\_deletion\_window\_in\_days](#input\_kms\_deletion\_window\_in\_days) | Key rotation window, set to 0 for no rotation. Only used when `enable_kms` is set to `true`. | `number` | `7` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | KMS key id to encrypted the resources. Ensure CloudWatch and Runner/Executor have access to the provided KMS key. | `string` | `""` | no |
| <a name="input_log_group_name"></a> [log\_group\_name](#input\_log\_group\_name) | Option to override the default name (`environment`) of the log group, requires `enable_cloudwatch_logging = true`. | `string` | `null` | no |
| <a name="input_metrics_autoscaling"></a> [metrics\_autoscaling](#input\_metrics\_autoscaling) | A list of metrics to collect. The allowed values are GroupDesiredCapacity, GroupInServiceCapacity, GroupPendingCapacity, GroupMinSize, GroupMaxSize, GroupInServiceInstances, GroupPendingInstances, GroupStandbyInstances, GroupStandbyCapacity, GroupTerminatingCapacity, GroupTerminatingInstances, GroupTotalCapacity, GroupTotalInstances. | `list(string)` | `null` | no |
| <a name="input_overrides"></a> [overrides](#input\_overrides) | This map provides the possibility to override some defaults. <br>The following attributes are supported: <br>  * `name_sg` set the name prefix and overwrite the `Name` tag for all security groups created by this module. <br>  * `name_runner_agent_instance` set the name prefix and override the `Name` tag for the EC2 gitlab runner instances defined in the auto launch configuration. <br>  * `name_docker_machine_runners` override the `Name` tag of EC2 instances created by the runner agent (used as name prefix for `docker_machine_version` >= 0.16.2).<br>  * `name_iam_objects` set the name prefix of all AWS IAM resources created by this module. | `map(string)` | <pre>{<br>  "name_docker_machine_runners": "",<br>  "name_iam_objects": "",<br>  "name_runner_agent_instance": "",<br>  "name_sg": ""<br>}</pre> | no |
| <a name="input_permissions_boundary"></a> [permissions\_boundary](#input\_permissions\_boundary) | Name of permissions boundary policy to attach to AWS IAM roles | `string` | `""` | no |
| <a name="input_prometheus_listen_address"></a> [prometheus\_listen\_address](#input\_prometheus\_listen\_address) | Defines an address (<host>:<port>) the Prometheus metrics HTTP server should listen on. | `string` | `""` | no |
| <a name="input_role_tags"></a> [role\_tags](#input\_role\_tags) | Map of tags that will be added to the role created. Useful for tag based authorization. | `map(string)` | `{}` | no |
| <a name="input_runner_agent_uses_private_address"></a> [runner\_agent\_uses\_private\_address](#input\_runner\_agent\_uses\_private\_address) | Restrict the runner agent to the use of a private IP address. If `runner_agent_uses_private_address` is set to `false` it will override the `runners_use_private_address` for the agent. | `bool` | `true` | no |
| <a name="input_runner_ami_filter"></a> [runner\_ami\_filter](#input\_runner\_ami\_filter) | List of maps used to create the AMI filter for the Gitlab runner docker-machine AMI. | `map(list(string))` | <pre>{<br>  "name": [<br>    "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"<br>  ]<br>}</pre> | no |
| <a name="input_runner_ami_owners"></a> [runner\_ami\_owners](#input\_runner\_ami\_owners) | The list of owners used to select the AMI of Gitlab runner docker-machine instances. | `list(string)` | <pre>[<br>  "099720109477"<br>]</pre> | no |
| <a name="input_runner_extra_config"></a> [runner\_extra\_config](#input\_runner\_extra\_config) | Extra commands to run as part of starting the runner | `string` | `""` | no |
| <a name="input_runner_iam_policy_arns"></a> [runner\_iam\_policy\_arns](#input\_runner\_iam\_policy\_arns) | List of policy ARNs to be added to the instance profile of the gitlab runner agent ec2 instance. | `list(string)` | `[]` | no |
| <a name="input_runner_iam_role_name"></a> [runner\_iam\_role\_name](#input\_runner\_iam\_role\_name) | IAM role name of the gitlab runner agent EC2 instance. If unspecified then `{name_iam_objects}-instance` is used | `string` | `""` | no |
| <a name="input_runner_instance_ebs_optimized"></a> [runner\_instance\_ebs\_optimized](#input\_runner\_instance\_ebs\_optimized) | Enable the GitLab runner instance to be EBS-optimized. | `bool` | `true` | no |
| <a name="input_runner_instance_enable_monitoring"></a> [runner\_instance\_enable\_monitoring](#input\_runner\_instance\_enable\_monitoring) | Enable the GitLab runner instance to have detailed monitoring. | `bool` | `true` | no |
| <a name="input_runner_instance_metadata_options"></a> [runner\_instance\_metadata\_options](#input\_runner\_instance\_metadata\_options) | Enable the Gitlab runner agent instance metadata service. | <pre>object({<br>    http_endpoint               = string<br>    http_tokens                 = string<br>    http_put_response_hop_limit = number<br>    instance_metadata_tags      = string<br>  })</pre> | <pre>{<br>  "http_endpoint": "enabled",<br>  "http_put_response_hop_limit": 2,<br>  "http_tokens": "required",<br>  "instance_metadata_tags": "disabled"<br>}</pre> | no |
| <a name="input_runner_instance_spot_price"></a> [runner\_instance\_spot\_price](#input\_runner\_instance\_spot\_price) | By setting a spot price bid price the runner agent will be created via a spot request. Be aware that spot instances can be stopped by AWS. Choose "on-demand-price" to pay up to the current on demand price for the instance type chosen. | `string` | `null` | no |
| <a name="input_runner_root_block_device"></a> [runner\_root\_block\_device](#input\_runner\_root\_block\_device) | The EC2 instance root block device configuration. Takes the following keys: `device_name`, `delete_on_termination`, `volume_type`, `volume_size`, `encrypted`, `iops`, `throughput`, `kms_key_id` | `map(string)` | `{}` | no |
| <a name="input_runner_tags"></a> [runner\_tags](#input\_runner\_tags) | Map of tags that will be added to runner EC2 instances. | `map(string)` | `{}` | no |
| <a name="input_runner_yum_update"></a> [runner\_yum\_update](#input\_runner\_yum\_update) | Run a yum update as part of starting the runner | `bool` | `true` | no |
| <a name="input_runners_add_dind_volumes"></a> [runners\_add\_dind\_volumes](#input\_runners\_add\_dind\_volumes) | Add certificates and docker.sock to the volumes to support docker-in-docker (dind) | `bool` | `false` | no |
| <a name="input_runners_additional_volumes"></a> [runners\_additional\_volumes](#input\_runners\_additional\_volumes) | Additional volumes that will be used in the runner config.toml, e.g Docker socket | `list(any)` | `[]` | no |
| <a name="input_runners_check_interval"></a> [runners\_check\_interval](#input\_runners\_check\_interval) | defines the interval length, in seconds, between new jobs check. | `number` | `3` | no |
| <a name="input_runners_clone_url"></a> [runners\_clone\_url](#input\_runners\_clone\_url) | Overwrites the URL for the GitLab instance. Use only if the runner can’t connect to the GitLab URL. | `string` | `""` | no |
| <a name="input_runners_concurrent"></a> [runners\_concurrent](#input\_runners\_concurrent) | Concurrent value for the runners, will be used in the runner config.toml. | `number` | `10` | no |
| <a name="input_runners_disable_cache"></a> [runners\_disable\_cache](#input\_runners\_disable\_cache) | Runners will not use local cache, will be used in the runner config.toml | `bool` | `false` | no |
| <a name="input_runners_docker_registry_mirror"></a> [runners\_docker\_registry\_mirror](#input\_runners\_docker\_registry\_mirror) | The docker registry mirror to use to avoid rate limiting by hub.docker.com | `string` | `""` | no |
| <a name="input_runners_docker_runtime"></a> [runners\_docker\_runtime](#input\_runners\_docker\_runtime) | docker runtime for runners, will be used in the runner config.toml | `string` | `""` | no |
| <a name="input_runners_docker_services"></a> [runners\_docker\_services](#input\_runners\_docker\_services) | adds `runners.docker.services` blocks to config.toml.  All fields must be set (examine the Dockerfile of the service image for the entrypoint - see ./examples/runner-default/main.tf) | <pre>list(object({<br>    name       = string<br>    alias      = string<br>    entrypoint = list(string)<br>    command    = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_runners_ebs_optimized"></a> [runners\_ebs\_optimized](#input\_runners\_ebs\_optimized) | Enable runners to be EBS-optimized. | `bool` | `true` | no |
| <a name="input_runners_environment_vars"></a> [runners\_environment\_vars](#input\_runners\_environment\_vars) | Environment variables during build execution, e.g. KEY=Value, see runner-public example. Will be used in the runner config.toml | `list(string)` | `[]` | no |
| <a name="input_runners_executor"></a> [runners\_executor](#input\_runners\_executor) | The executor to use. Currently supports `docker+machine` or `docker`. | `string` | `"docker+machine"` | no |
| <a name="input_runners_extra_hosts"></a> [runners\_extra\_hosts](#input\_runners\_extra\_hosts) | Extra hosts that will be used in the runner config.toml, e.g other-host:127.0.0.1 | `list(any)` | `[]` | no |
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
| <a name="input_runners_output_limit"></a> [runners\_output\_limit](#input\_runners\_output\_limit) | Sets the maximum build log size in kilobytes, by default set to 4096 (4MB). | `number` | `4096` | no |
| <a name="input_runners_post_build_script"></a> [runners\_post\_build\_script](#input\_runners\_post\_build\_script) | Commands to be executed on the Runner just after executing the build, but before executing after\_script. | `string` | `"\"\""` | no |
| <a name="input_runners_pre_build_script"></a> [runners\_pre\_build\_script](#input\_runners\_pre\_build\_script) | Script to execute in the pipeline just before the build, will be used in the runner config.toml | `string` | `"\"\""` | no |
| <a name="input_runners_pre_clone_script"></a> [runners\_pre\_clone\_script](#input\_runners\_pre\_clone\_script) | Commands to be executed on the Runner before cloning the Git repository. this can be used to adjust the Git client configuration first, for example. | `string` | `"\"\""` | no |
| <a name="input_runners_privileged"></a> [runners\_privileged](#input\_runners\_privileged) | Runners will run in privileged mode, will be used in the runner config.toml | `bool` | `true` | no |
| <a name="input_runners_pull_policies"></a> [runners\_pull\_policies](#input\_runners\_pull\_policies) | pull policies for the runners, will be used in the runner config.toml, for Gitlab Runner >= 13.8, see https://docs.gitlab.com/runner/executors/docker.html#using-multiple-pull-policies | `list(string)` | <pre>[<br>  "always"<br>]</pre> | no |
| <a name="input_runners_pull_policy"></a> [runners\_pull\_policy](#input\_runners\_pull\_policy) | Deprecated! Use runners\_pull\_policies instead. pull\_policy for the runners, will be used in the runner config.toml | `string` | `""` | no |
| <a name="input_runners_request_concurrency"></a> [runners\_request\_concurrency](#input\_runners\_request\_concurrency) | Limit number of concurrent requests for new jobs from GitLab (default 1). | `number` | `1` | no |
| <a name="input_runners_request_spot_instance"></a> [runners\_request\_spot\_instance](#input\_runners\_request\_spot\_instance) | Whether or not to request spot instances via docker-machine | `bool` | `true` | no |
| <a name="input_runners_root_size"></a> [runners\_root\_size](#input\_runners\_root\_size) | Runner instance root size in GB. | `number` | `16` | no |
| <a name="input_runners_services_volumes_tmpfs"></a> [runners\_services\_volumes\_tmpfs](#input\_runners\_services\_volumes\_tmpfs) | Mount a tmpfs in gitlab service container. https://docs.gitlab.com/runner/executors/docker.html#mounting-a-directory-in-ram | <pre>list(object({<br>    volume  = string<br>    options = string<br>  }))</pre> | `[]` | no |
| <a name="input_runners_shm_size"></a> [runners\_shm\_size](#input\_runners\_shm\_size) | shm\_size for the runners, will be used in the runner config.toml | `number` | `0` | no |
| <a name="input_runners_token"></a> [runners\_token](#input\_runners\_token) | Token for the runner, will be used in the runner config.toml. | `string` | `"__REPLACED_BY_USER_DATA__"` | no |
| <a name="input_runners_use_private_address"></a> [runners\_use\_private\_address](#input\_runners\_use\_private\_address) | Restrict runners to the use of a private IP address. If `runner_agent_uses_private_address` is set to `true`(default), `runners_use_private_address` will also apply for the agent. | `bool` | `true` | no |
| <a name="input_runners_userdata"></a> [runners\_userdata](#input\_runners\_userdata) | Cloud-init user data that will be passed to the runner ec2 instance. Available only for `docker+machine` driver. Should not be base64 encrypted. | `string` | `""` | no |
| <a name="input_runners_volume_type"></a> [runners\_volume\_type](#input\_runners\_volume\_type) | Runner instance volume type | `string` | `"gp2"` | no |
| <a name="input_runners_volumes_tmpfs"></a> [runners\_volumes\_tmpfs](#input\_runners\_volumes\_tmpfs) | Mount a tmpfs in runner container. https://docs.gitlab.com/runner/executors/docker.html#mounting-a-directory-in-ram | <pre>list(object({<br>    volume  = string<br>    options = string<br>  }))</pre> | `[]` | no |
| <a name="input_schedule_config"></a> [schedule\_config](#input\_schedule\_config) | Map containing the configuration of the ASG scale-out and scale-in for the runner instance. Will only be used if enable\_schedule is set to true. | `map(any)` | <pre>{<br>  "scale_in_count": 0,<br>  "scale_in_recurrence": "0 18 * * 1-5",<br>  "scale_out_count": 1,<br>  "scale_out_recurrence": "0 8 * * 1-5"<br>}</pre> | no |
| <a name="input_secure_parameter_store_runner_sentry_dsn"></a> [secure\_parameter\_store\_runner\_sentry\_dsn](#input\_secure\_parameter\_store\_runner\_sentry\_dsn) | The Sentry DSN name used to store the Sentry DSN in Secure Parameter Store | `string` | `"sentry-dsn"` | no |
| <a name="input_sentry_dsn"></a> [sentry\_dsn](#input\_sentry\_dsn) | Sentry DSN of the project for the runner to use (uses legacy DSN format) | `string` | `"__SENTRY_DSN_REPLACED_BY_USER_DATA__"` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Subnet id used for the runner and executors. Must belong to the VPC specified above. | `string` | `""` | no |
| <a name="input_subnet_id_runners"></a> [subnet\_id\_runners](#input\_subnet\_id\_runners) | Deprecated! Use subnet\_id instead. List of subnets used for hosting the gitlab-runners. | `string` | `""` | no |
| <a name="input_subnet_ids_gitlab_runner"></a> [subnet\_ids\_gitlab\_runner](#input\_subnet\_ids\_gitlab\_runner) | Deprecated! Use subnet\_id instead. Subnet used for hosting the GitLab runner. | `list(string)` | `[]` | no |
| <a name="input_suppressed_tags"></a> [suppressed\_tags](#input\_suppressed\_tags) | List of tag keys which are removed from tags, agent\_tags and runner\_tags and never added as default tag by the module. | `list(string)` | `[]` | no |
=======
| <a name="input_iam_object_prefix"></a> [iam\_object\_prefix](#input\_iam\_object\_prefix) | Set the name prefix of all AWS IAM resources. | `string` | `""` | no |
| <a name="input_iam_permissions_boundary"></a> [iam\_permissions\_boundary](#input\_iam\_permissions\_boundary) | Name of permissions boundary policy to attach to AWS IAM roles | `string` | `""` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | KMS key id to encrypt the resources. Ensure that CloudWatch and Runner/Runner Workers have access to the provided KMS key. | `string` | `""` | no |
| <a name="input_kms_managed_alias_name"></a> [kms\_managed\_alias\_name](#input\_kms\_managed\_alias\_name) | Alias added to the created KMS key. | `string` | `""` | no |
| <a name="input_kms_managed_deletion_rotation_window_in_days"></a> [kms\_managed\_deletion\_rotation\_window\_in\_days](#input\_kms\_managed\_deletion\_rotation\_window\_in\_days) | Key deletion/rotation window for the created KMS key. Set to 0 for no rotation/deletion window. | `number` | `7` | no |
| <a name="input_runner_ami_filter"></a> [runner\_ami\_filter](#input\_runner\_ami\_filter) | List of maps used to create the AMI filter for the Runner AMI. Must resolve to an Amazon Linux 1 or 2 image. | `map(list(string))` | <pre>{<br>  "name": [<br>    "amzn2-ami-hvm-2.*-x86_64-ebs"<br>  ]<br>}</pre> | no |
| <a name="input_runner_ami_owners"></a> [runner\_ami\_owners](#input\_runner\_ami\_owners) | The list of owners used to select the AMI of the Runner instance. | `list(string)` | <pre>[<br>  "amazon"<br>]</pre> | no |
| <a name="input_runner_cloudwatch"></a> [runner\_cloudwatch](#input\_runner\_cloudwatch) | enable = Boolean used to enable or disable the CloudWatch logging.<br>log\_group\_name = Option to override the default name (`environment`) of the log group. Requires `enable = true`.<br>retention\_days = Retention for cloudwatch logs. Defaults to unlimited. Requires `enable = true`. | <pre>object({<br>    enable         = optional(bool, true)<br>    log_group_name = optional(string, null)<br>    retention_days = optional(number, 0)<br>  })</pre> | `{}` | no |
| <a name="input_runner_enable_asg_recreation"></a> [runner\_enable\_asg\_recreation](#input\_runner\_enable\_asg\_recreation) | Enable automatic redeployment of the Runner's ASG when the Launch Configs change. | `bool` | `true` | no |
| <a name="input_runner_gitlab"></a> [runner\_gitlab](#input\_runner\_gitlab) | ca\_certificate = Trusted CA certificate bundle (PEM format).<br>certificate = Certificate of the GitLab instance to connect to (PEM format).<br>registration\_token = Registration token to use to register the Runner. Do not use. This is replaced by the `registration_token` in `runner_gitlab_registration_config`.<br>runner\_version = Version of the [GitLab Runner](https://gitlab.com/gitlab-org/gitlab-runner/-/releases).<br>url = URL of the GitLab instance to connect to.<br>url\_clone = URL of the GitLab instance to clone from. Use only if the agent can’t connect to the GitLab URL. | <pre>object({<br>    ca_certificate     = optional(string, "")<br>    certificate        = optional(string, "")<br>    registration_token = optional(string, "__REPLACED_BY_USER_DATA__")<br>    runner_version     = optional(string, "15.8.2")<br>    url                = optional(string, "")<br>    url_clone          = optional(string, "")<br>  })</pre> | n/a | yes |
| <a name="input_runner_gitlab_registration_config"></a> [runner\_gitlab\_registration\_config](#input\_runner\_gitlab\_registration\_config) | Configuration used to register the Runner. See the README for an example, or reference the examples in the examples directory of this repo. There is also a good GitLab documentation available at: https://docs.gitlab.com/ee/ci/runners/configure_runners.html | <pre>object({<br>    registration_token = optional(string, "")<br>    tag_list           = optional(string, "")<br>    description        = optional(string, "")<br>    locked_to_project  = optional(string, "")<br>    run_untagged       = optional(string, "")<br>    maximum_timeout    = optional(string, "")<br>    access_level       = optional(string, "not_protected") # this is the only mandatory field calling the GitLab get token for executor operation<br>  })</pre> | `{}` | no |
| <a name="input_runner_gitlab_registration_token_secure_parameter_store_name"></a> [runner\_gitlab\_registration\_token\_secure\_parameter\_store\_name](#input\_runner\_gitlab\_registration\_token\_secure\_parameter\_store\_name) | The name of the SSM parameter to read the GitLab Runner registration token from. | `string` | `"gitlab-runner-registration-token"` | no |
| <a name="input_runner_gitlab_token_secure_parameter_store"></a> [runner\_gitlab\_token\_secure\_parameter\_store](#input\_runner\_gitlab\_token\_secure\_parameter\_store) | Name of the Secure Parameter Store entry to hold the GitLab Runner token. | `string` | `"runner-token"` | no |
| <a name="input_runner_install"></a> [runner\_install](#input\_runner\_install) | amazon\_ecr\_credentials\_helper = Install amazon-ecr-credential-helper inside `userdata_pre_install` script<br>docker\_machine\_download\_url = URL to download docker machine binary. If not set, the docker machine version will be used to download the binary.<br>docker\_machine\_version = By default docker\_machine\_download\_url is used to set the docker machine version. This version will be ignored once `docker_machine_download_url` is set. The version number is maintained by the CKI project. Check out at https://gitlab.com/cki-project/docker-machine/-/releases<br>pre\_install\_script = Script to run before installing the Runner<br>post\_install\_script = Script to run after installing the Runner<br>start\_script = Script to run after starting the Runner<br>yum\_update = Update the yum packages before installing the Runner | <pre>object({<br>    amazon_ecr_credential_helper = optional(bool, false)<br>    docker_machine_download_url  = optional(string, "")<br>    docker_machine_version       = optional(string, "0.16.2-gitlab.19-cki.2")<br>    pre_install_script           = optional(string, "")<br>    post_install_script          = optional(string, "")<br>    start_script                 = optional(string, "")<br>    yum_update                   = optional(bool, true)<br>  })</pre> | `{}` | no |
| <a name="input_runner_instance"></a> [runner\_instance](#input\_runner\_instance) | additional\_tags = Map of tags that will be added to the Runner instance.<br>collect\_autoscaling\_metrics = A list of metrics to collect. The allowed values are GroupDesiredCapacity, GroupInServiceCapacity, GroupPendingCapacity, GroupMinSize, GroupMaxSize, GroupInServiceInstances, GroupPendingInstances, GroupStandbyInstances, GroupStandbyCapacity, GroupTerminatingCapacity, GroupTerminatingInstances, GroupTotalCapacity, GroupTotalInstances.<br>ebs\_optimized = Enable EBS optimization for the Runner instance.<br>max\_lifetime\_seconds = The maximum time a Runner should live before it is killed.<br>monitoring = Enable the detailed monitoring on the Runner instance.<br>name = Name of the Runner instance.<br>name\_prefix = Set the name prefix and override the `Name` tag for the Runner instance.<br>private\_address\_only = Restrict the Runner to use private IP addresses only. If this is set to `true` the Runner will use a private IP address only in case the Runner Workers use private addresses only.<br>root\_device\_config = The Runner's root block device configuration. Takes the following keys: `device_name`, `delete_on_termination`, `volume_type`, `volume_size`, `encrypted`, `iops`, `throughput`, `kms_key_id`<br>spot\_price = By setting a spot price bid price the Runner is created via a spot request. Be aware that spot instances can be stopped by AWS. Choose \"on-demand-price\" to pay up to the current on demand price for the instance type chosen.<br>ssm\_access = Allows to connect to the Runner via SSM.<br>type = EC2 instance type used.<br>use\_eip = Assigns an EIP to the Runner. | <pre>object({<br>    additional_tags             = optional(map(string))<br>    collect_autoscaling_metrics = optional(list(string), null)<br>    ebs_optimized               = optional(bool, true)<br>    max_lifetime_seconds        = optional(number, null)<br>    monitoring                  = optional(bool, true)<br>    name                        = string<br>    name_prefix                 = optional(string)<br>    private_address_only        = optional(bool, true)<br>    root_device_config          = optional(map(string), {})<br>    spot_price                  = optional(string, null)<br>    ssm_access                  = optional(bool, false)<br>    type                        = optional(string, "t3.micro")<br>    use_eip                     = optional(bool, false)<br>  })</pre> | <pre>{<br>  "name": "gitlab-runner"<br>}</pre> | no |
| <a name="input_runner_manager"></a> [runner\_manager](#input\_runner\_manager) | For details check https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-global-section<br><br>gitlab\_check\_interval = Number of seconds between checking for available jobs (check\_interval)<br>maximum\_concurrent\_jobs = The maximum number of jobs which can be processed by all Runners at the same time (concurrent).<br>prometheus\_listen\_address = Defines an address (<host>:<port>) the Prometheus metrics HTTP server should listen on (listen\_address).<br>sentry\_dsn = Sentry DSN of the project for the Runner Manager to use (uses legacy DSN format) (sentry\_dsn) | <pre>object({<br>    gitlab_check_interval     = optional(number, 3)<br>    maximum_concurrent_jobs   = optional(number, 10)<br>    prometheus_listen_address = optional(string, "")<br>    sentry_dsn                = optional(string, "__SENTRY_DSN_REPLACED_BY_USER_DATA__")<br>  })</pre> | `{}` | no |
| <a name="input_runner_metadata_options"></a> [runner\_metadata\_options](#input\_runner\_metadata\_options) | Enable the Runner instance metadata service. IMDSv2 is enabled by default. | <pre>object({<br>    http_endpoint               = string<br>    http_tokens                 = string<br>    http_put_response_hop_limit = number<br>    instance_metadata_tags      = string<br>  })</pre> | <pre>{<br>  "http_endpoint": "enabled",<br>  "http_put_response_hop_limit": 2,<br>  "http_tokens": "required",<br>  "instance_metadata_tags": "disabled"<br>}</pre> | no |
| <a name="input_runner_networking"></a> [runner\_networking](#input\_runner\_networking) | allow\_incoming\_ping = Allow ICMP Ping to the Runner. Specify `allow_incoming_ping_security_group_ids` too!<br>allow\_incoming\_ping\_security\_group\_ids = A list of security group ids that are allowed to ping the Runner.<br>security\_group\_description = A description for the Runner's security group<br>security\_group\_ids = IDs of security groups to add to the Runner. | <pre>object({<br>    allow_incoming_ping                    = optional(bool, false)<br>    allow_incoming_ping_security_group_ids = optional(list(string), [])<br>    security_group_description             = optional(string, "A security group containing gitlab-runner agent instances")<br>    security_group_ids                     = optional(list(string), [])<br>  })</pre> | `{}` | no |
| <a name="input_runner_networking_egress_rules"></a> [runner\_networking\_egress\_rules](#input\_runner\_networking\_egress\_rules) | List of egress rules for the Runner. | <pre>list(object({<br>    cidr_blocks      = list(string)<br>    ipv6_cidr_blocks = list(string)<br>    prefix_list_ids  = list(string)<br>    from_port        = number<br>    protocol         = string<br>    security_groups  = list(string)<br>    self             = bool<br>    to_port          = number<br>    description      = string<br>  }))</pre> | <pre>[<br>  {<br>    "cidr_blocks": [<br>      "0.0.0.0/0"<br>    ],<br>    "description": null,<br>    "from_port": 0,<br>    "ipv6_cidr_blocks": [<br>      "::/0"<br>    ],<br>    "prefix_list_ids": null,<br>    "protocol": "-1",<br>    "security_groups": null,<br>    "self": null,<br>    "to_port": 0<br>  }<br>]</pre> | no |
| <a name="input_runner_role"></a> [runner\_role](#input\_runner\_role) | additional\_tags = Map of tags that will be added to the role created. Useful for tag based authorization.<br>allow\_iam\_service\_linked\_role\_creation = Boolean used to control attaching the policy to the Runner to create service linked roles.<br>assume\_role\_policy\_json = The assume role policy for the Runner.<br>create\_role\_profile = Whether to create the IAM role/profile for the Runner. If you provide your own role, make sure that it has the required permissions.<br>policy\_arns = List of policy ARNs to be added to the instance profile of the Runner.<br>role\_profile\_name = IAM role/profile name for the Runner. If unspecified then `${var.iam_object_prefix}-instance` is used. | <pre>object({<br>    additional_tags                        = optional(map(string))<br>    allow_iam_service_linked_role_creation = optional(bool, true)<br>    assume_role_policy_json                = optional(string, "")<br>    create_role_profile                    = optional(bool, true)<br>    policy_arns                            = optional(list(string), [])<br>    role_profile_name                      = optional(string)<br>  })</pre> | `{}` | no |
| <a name="input_runner_schedule_config"></a> [runner\_schedule\_config](#input\_runner\_schedule\_config) | Map containing the configuration of the ASG scale-out and scale-in for the Runner. Will only be used if `agent_schedule_enable` is set to `true`. | `map(any)` | <pre>{<br>  "scale_in_count": 0,<br>  "scale_in_recurrence": "0 18 * * 1-5",<br>  "scale_in_time_zone": "Etc/UTC",<br>  "scale_out_count": 1,<br>  "scale_out_recurrence": "0 8 * * 1-5",<br>  "scale_out_time_zone": "Etc/UTC"<br>}</pre> | no |
| <a name="input_runner_schedule_enable"></a> [runner\_schedule\_enable](#input\_runner\_schedule\_enable) | Set to `true` to enable the auto scaling group schedule for the Runner. | `bool` | `false` | no |
| <a name="input_runner_sentry_secure_parameter_store_name"></a> [runner\_sentry\_secure\_parameter\_store\_name](#input\_runner\_sentry\_secure\_parameter\_store\_name) | The Sentry DSN name used to store the Sentry DSN in Secure Parameter Store | `string` | `"sentry-dsn"` | no |
| <a name="input_runner_terminate_ec2_lifecycle_hook_name"></a> [runner\_terminate\_ec2\_lifecycle\_hook\_name](#input\_runner\_terminate\_ec2\_lifecycle\_hook\_name) | Specifies a custom name for the ASG terminate lifecycle hook and related resources. | `string` | `null` | no |
| <a name="input_runner_terraform_timeout_delete_asg"></a> [runner\_terraform\_timeout\_delete\_asg](#input\_runner\_terraform\_timeout\_delete\_asg) | Timeout when trying to delete the Runner ASG. | `string` | `"10m"` | no |
| <a name="input_runner_worker"></a> [runner\_worker](#input\_runner\_worker) | For detailed information, check https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section.<br><br>environment\_variables = List of environment variables to add to the Runner Worker (environment).<br>max\_jobs = Number of jobs which can be processed in parallel by the Runner Worker.<br>output\_limit = Sets the maximum build log size in kilobytes. Default is 4MB (output\_limit).<br>request\_concurrency = Limit number of concurrent requests for new jobs from GitLab (default 1) (request\_concurrency).<br>ssm\_access = Allows to connect to the Runner Worker via SSM.<br>type = The Runner Worker type to use. Currently supports `docker+machine` or `docker`. | <pre>object({<br>    environment_variables = optional(list(string), [])<br>    max_jobs              = optional(number, 0)<br>    output_limit          = optional(number, 4096)<br>    request_concurrency   = optional(number, 1)<br>    ssm_access            = optional(bool, false)<br>    type                  = optional(string, "docker+machine")<br>  })</pre> | `{}` | no |
| <a name="input_runner_worker_cache"></a> [runner\_worker\_cache](#input\_runner\_worker\_cache) | Configuration to control the creation of the cache bucket. By default the bucket will be created and used as shared<br>cache. To use the same cache across multiple Runner Worker disable the creation of the cache and provide a policy and<br>bucket name. See the public runner example for more details."<br><br>For detailed documentation check https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runnerscaches3-section<br><br>access\_log\_bucker\_id = The ID of the bucket where the access logs are stored.<br>access\_log\_bucket\_prefix = The bucket prefix for the access logs.<br>authentication\_type = A string that declares the AuthenticationType for [runners.cache.s3]. Can either be 'iam' or 'credentials'<br>bucket = Name of the cache bucket. Requires `create = false`.<br>bucket\_prefix = Prefix for s3 cache bucket name. Requires `create = true`.<br>create = Boolean used to enable or disable the creation of the cache bucket.<br>expiration\_days = Number of days before cache objects expire. Requires `create = true`.<br>include\_account\_id = Boolean used to include the account id in the cache bucket name. Requires `create = true`.<br>policy = Policy to use for the cache bucket. Requires `create = false`.<br>random\_suffix = Boolean used to enable or disable the use of a random string suffix on the cache bucket name. Requires `create = true`.<br>shared = Boolean used to enable or disable the use of the cache bucket as shared cache.<br>versioning = Boolean used to enable versioning on the cache bucket. Requires `create = true`. | <pre>object({<br>    access_log_bucket_id     = optional(string, null)<br>    access_log_bucket_prefix = optional(string, null)<br>    authentication_type      = optional(string, "iam")<br>    bucket                   = optional(string, "")<br>    bucket_prefix            = optional(string, "")<br>    create                   = optional(bool, true)<br>    expiration_days          = optional(number, 1)<br>    include_account_id       = optional(bool, true)<br>    policy                   = optional(string, "")<br>    random_suffix            = optional(bool, false)<br>    shared                   = optional(bool, false)<br>    versioning               = optional(bool, false)<br>  })</pre> | `{}` | no |
| <a name="input_runner_worker_docker_add_dind_volumes"></a> [runner\_worker\_docker\_add\_dind\_volumes](#input\_runner\_worker\_docker\_add\_dind\_volumes) | Add certificates and docker.sock to the volumes to support docker-in-docker (dind) | `bool` | `false` | no |
| <a name="input_runner_worker_docker_machine_ami_filter"></a> [runner\_worker\_docker\_machine\_ami\_filter](#input\_runner\_worker\_docker\_machine\_ami\_filter) | List of maps used to create the AMI filter for the Runner Worker. | `map(list(string))` | <pre>{<br>  "name": [<br>    "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"<br>  ]<br>}</pre> | no |
| <a name="input_runner_worker_docker_machine_ami_owners"></a> [runner\_worker\_docker\_machine\_ami\_owners](#input\_runner\_worker\_docker\_machine\_ami\_owners) | The list of owners used to select the AMI of the Runner Worker. | `list(string)` | <pre>[<br>  "099720109477"<br>]</pre> | no |
| <a name="input_runner_worker_docker_machine_autoscaling_options"></a> [runner\_worker\_docker\_machine\_autoscaling\_options](#input\_runner\_worker\_docker\_machine\_autoscaling\_options) | Set autoscaling parameters based on periods, see https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runnersmachine-section | <pre>list(object({<br>    periods           = list(string)<br>    idle_count        = optional(number)<br>    idle_scale_factor = optional(number)<br>    idle_count_min    = optional(number)<br>    idle_time         = optional(number)<br>    timezone          = optional(string, "UTC")<br>  }))</pre> | `[]` | no |
| <a name="input_runner_worker_docker_machine_ec2_metadata_options"></a> [runner\_worker\_docker\_machine\_ec2\_metadata\_options](#input\_runner\_worker\_docker\_machine\_ec2\_metadata\_options) | Enable the Runner Worker metadata service. Requires you use CKI maintained docker machines. | <pre>object({<br>    http_tokens                 = string<br>    http_put_response_hop_limit = number<br>  })</pre> | <pre>{<br>  "http_put_response_hop_limit": 2,<br>  "http_tokens": "required"<br>}</pre> | no |
| <a name="input_runner_worker_docker_machine_ec2_options"></a> [runner\_worker\_docker\_machine\_ec2\_options](#input\_runner\_worker\_docker\_machine\_ec2\_options) | List of additional options for the docker+machine config. Each element of this list must be a key=value pair. E.g. '["amazonec2-zone=a"]' | `list(string)` | `[]` | no |
| <a name="input_runner_worker_docker_machine_extra_egress_rules"></a> [runner\_worker\_docker\_machine\_extra\_egress\_rules](#input\_runner\_worker\_docker\_machine\_extra\_egress\_rules) | List of egress rules for the Runner Workers. | <pre>list(object({<br>    cidr_blocks      = list(string)<br>    ipv6_cidr_blocks = list(string)<br>    prefix_list_ids  = list(string)<br>    from_port        = number<br>    protocol         = string<br>    security_groups  = list(string)<br>    self             = bool<br>    to_port          = number<br>    description      = string<br>  }))</pre> | <pre>[<br>  {<br>    "cidr_blocks": [<br>      "0.0.0.0/0"<br>    ],<br>    "description": "Allow all egress traffic for Runner Workers.",<br>    "from_port": 0,<br>    "ipv6_cidr_blocks": [<br>      "::/0"<br>    ],<br>    "prefix_list_ids": null,<br>    "protocol": "-1",<br>    "security_groups": null,<br>    "self": null,<br>    "to_port": 0<br>  }<br>]</pre> | no |
| <a name="input_runner_worker_docker_machine_fleet"></a> [runner\_worker\_docker\_machine\_fleet](#input\_runner\_worker\_docker\_machine\_fleet) | enable = Activates the fleet mode on the Runner. https://gitlab.com/cki-project/docker-machine/-/blob/v0.16.2-gitlab.19-cki.2/docs/drivers/aws.md#fleet-mode<br>key\_pair\_name = The name of the key pair used by the Runner to connect to the docker-machine Runner Workers. This variable is only supported when `enables` is set to `true`. | <pre>object({<br>    enable        = bool<br>    key_pair_name = optional(string, "fleet-key")<br>  })</pre> | <pre>{<br>  "enable": false<br>}</pre> | no |
| <a name="input_runner_worker_docker_machine_instance"></a> [runner\_worker\_docker\_machine\_instance](#input\_runner\_worker\_docker\_machine\_instance) | For detailed documentation check https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runnersmachine-section<br><br>docker\_registry\_mirror\_url = The URL of the Docker registry mirror to use for the Runner Worker.<br>destroy\_after\_max\_builds = Destroy the instance after the maximum number of builds has been reached.<br>ebs\_optimized = Enable EBS optimization for the Runner Worker.<br>idle\_count = Number of idle Runner Worker instances (not working for the Docker Runner Worker) (IdleCount).<br>idle\_time = Idle time of the Runner Worker before they are destroyed (not working for the Docker Runner Worker) (IdleTime).<br>max\_growth\_rate = The maximum number of machines that can be added to the runner in parallel.<br>monitoring = Enable detailed monitoring for the Runner Worker.<br>name\_prefix = Set the name prefix and override the `Name` tag for the Runner Worker.<br>private\_address\_only = Restrict Runner Worker to the use of a private IP address. If `runner_instance.use_private_address_only` is set to `true` (default), `runner_worker_docker_machine_instance.private_address_only` will also apply for the Runner.<br>root\_size = The size of the root volume for the Runner Worker.<br>start\_script = Cloud-init user data that will be passed to the Runner Worker. Should not be base64 encrypted.<br>subnet\_ids = The list of subnet IDs to use for the Runner Worker when the fleet mode is enabled.<br>types = The type of instance to use for the Runner Worker. In case of fleet mode, multiple instance types are supported.<br>volume\_type = The type of volume to use for the Runner Worker. | <pre>object({<br>    destroy_after_max_builds   = optional(number, 0)<br>    docker_registry_mirror_url = optional(string, "")<br>    ebs_optimized              = optional(bool, true)<br>    idle_count                 = optional(number, 0)<br>    idle_time                  = optional(number, 600)<br>    max_growth_rate            = optional(number, 0)<br>    monitoring                 = optional(bool, false)<br>    name_prefix                = optional(string, "")<br>    private_address_only       = optional(bool, true)<br>    root_size                  = optional(number, 8)<br>    start_script               = optional(string, "")<br>    subnet_ids                 = optional(list(string), [])<br>    types                      = optional(list(string), ["m5.large"])<br>    volume_type                = optional(string, "gp2")<br>  })</pre> | `{}` | no |
| <a name="input_runner_worker_docker_machine_instance_spot"></a> [runner\_worker\_docker\_machine\_instance\_spot](#input\_runner\_worker\_docker\_machine\_instance\_spot) | enable = Enable spot instances for the Runner Worker.<br>max\_price = The maximum price willing to pay. By default the price is limited by the current on demand price for the instance type chosen. | <pre>object({<br>    enable    = optional(bool, true)<br>    max_price = optional(string, "on-demand-price")<br>  })</pre> | `{}` | no |
| <a name="input_runner_worker_docker_machine_role"></a> [runner\_worker\_docker\_machine\_role](#input\_runner\_worker\_docker\_machine\_role) | additional\_tags = Map of tags that will be added to the Runner Worker.<br>assume\_role\_policy\_json = Assume role policy for the Runner Worker.<br>policy\_arns = List of ARNs of IAM policies to attach to the Runner Workers.<br>profile\_name    = Name of the IAM profile to attach to the Runner Workers. | <pre>object({<br>    additional_tags         = optional(map(string), {})<br>    assume_role_policy_json = optional(string, "")<br>    policy_arns             = optional(list(string), [])<br>    profile_name            = optional(string, "")<br>  })</pre> | `{}` | no |
| <a name="input_runner_worker_docker_machine_security_group_description"></a> [runner\_worker\_docker\_machine\_security\_group\_description](#input\_runner\_worker\_docker\_machine\_security\_group\_description) | A description for the Runner Worker security group | `string` | `"A security group containing Runner Worker instances"` | no |
| <a name="input_runner_worker_docker_options"></a> [runner\_worker\_docker\_options](#input\_runner\_worker\_docker\_options) | Options added to the [runners.docker] section of config.toml to configure the Docker container of the Runner Worker. For<br>    details check https://docs.gitlab.com/runner/configuration/advanced-configuration.html<br><br>    Default values if the option is not given:<br>      disable\_cache = "false"<br>      image         = "docker:18.03.1-ce"<br>      privileged    = "true"<br>      pull\_policy   = "always"<br>      shm\_size      = 0<br>      tls\_verify    = "false"<br>      volumes       = "/cache" | <pre>object({<br>    allowed_images               = optional(list(string))<br>    allowed_pull_policies        = optional(list(string))<br>    allowed_services             = optional(list(string))<br>    cache_dir                    = optional(string)<br>    cap_add                      = optional(list(string))<br>    cap_drop                     = optional(list(string))<br>    container_labels             = optional(list(string))<br>    cpuset_cpus                  = optional(string)<br>    cpu_shares                   = optional(number)<br>    cpus                         = optional(string)<br>    devices                      = optional(list(string))<br>    device_cgroup_rules          = optional(list(string))<br>    disable_cache                = optional(bool, false)<br>    disable_entrypoint_overwrite = optional(bool)<br>    dns                          = optional(list(string))<br>    dns_search                   = optional(list(string))<br>    extra_hosts                  = optional(list(string))<br>    gpus                         = optional(string)<br>    helper_image                 = optional(string)<br>    helper_image_flavor          = optional(string)<br>    host                         = optional(string)<br>    hostname                     = optional(string)<br>    image                        = optional(string, "docker:18.03.1-ce")<br>    isolation                    = optional(string)<br>    links                        = optional(list(string))<br>    mac_address                  = optional(string)<br>    memory                       = optional(string)<br>    memory_swap                  = optional(string)<br>    memory_reservation           = optional(string)<br>    network_mode                 = optional(string)<br>    oom_kill_disable             = optional(bool)<br>    oom_score_adjust             = optional(number)<br>    privileged                   = optional(bool, true)<br>    pull_policies                = optional(list(string), ["always"])<br>    runtime                      = optional(string)<br>    security_opt                 = optional(list(string))<br>    shm_size                     = optional(number, 0)<br>    sysctls                      = optional(list(string))<br>    tls_cert_path                = optional(string)<br>    tls_verify                   = optional(bool, false)<br>    user                         = optional(string)<br>    userns_mode                  = optional(string)<br>    volumes                      = optional(list(string), ["/cache"])<br>    volumes_from                 = optional(list(string))<br>    volume_driver                = optional(string)<br>    wait_for_services_timeout    = optional(number)<br>  })</pre> | <pre>{<br>  "disable_cache": "false",<br>  "image": "docker:18.03.1-ce",<br>  "privileged": "true",<br>  "pull_policy": "always",<br>  "shm_size": 0,<br>  "tls_verify": "false",<br>  "volumes": [<br>    "/cache"<br>  ]<br>}</pre> | no |
| <a name="input_runner_worker_docker_services"></a> [runner\_worker\_docker\_services](#input\_runner\_worker\_docker\_services) | Starts additional services with the Docker container. All fields must be set (examine the Dockerfile of the service image for the entrypoint - see ./examples/runner-default/main.tf) | <pre>list(object({<br>    name       = string<br>    alias      = string<br>    entrypoint = list(string)<br>    command    = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_runner_worker_docker_services_volumes_tmpfs"></a> [runner\_worker\_docker\_services\_volumes\_tmpfs](#input\_runner\_worker\_docker\_services\_volumes\_tmpfs) | Mount a tmpfs in gitlab service container. https://docs.gitlab.com/runner/executors/docker.html#mounting-a-directory-in-ram | <pre>list(object({<br>    volume  = string<br>    options = string<br>  }))</pre> | `[]` | no |
| <a name="input_runner_worker_docker_volumes_tmpfs"></a> [runner\_worker\_docker\_volumes\_tmpfs](#input\_runner\_worker\_docker\_volumes\_tmpfs) | Mount a tmpfs in Executor container. https://docs.gitlab.com/runner/executors/docker.html#mounting-a-directory-in-ram | <pre>list(object({<br>    volume  = string<br>    options = string<br>  }))</pre> | `[]` | no |
| <a name="input_runner_worker_gitlab_pipeline"></a> [runner\_worker\_gitlab\_pipeline](#input\_runner\_worker\_gitlab\_pipeline) | post\_build\_script = Script to execute in the pipeline just after the build, but before executing after\_script.<br>pre\_build\_script = Script to execute in the pipeline just before the build.<br>pre\_clone\_script = Script to execute in the pipeline before cloning the Git repository. this can be used to adjust the Git client configuration first, for example. | <pre>object({<br>    post_build_script = optional(string, "\"\"")<br>    pre_build_script  = optional(string, "\"\"")<br>    pre_clone_script  = optional(string, "\"\"")<br>  })</pre> | `{}` | no |
| <a name="input_security_group_prefix"></a> [security\_group\_prefix](#input\_security\_group\_prefix) | Set the name prefix and overwrite the `Name` tag for all security groups. | `string` | `""` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Subnet id used for the Runner and Runner Workers. Must belong to the `vpc_id`. In case the fleet mode is used, multiple subnets for<br>the Runner Workers can be provided with runner\_worker\_docker\_machine\_instance.subnet\_ids. | `string` | n/a | yes |
| <a name="input_suppressed_tags"></a> [suppressed\_tags](#input\_suppressed\_tags) | List of tag keys which are automatically removed and never added as default tag by the module. | `list(string)` | `[]` | no |
>>>>>>> origin/main
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags that will be added to created resources. By default resources will be tagged with name and environment. | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The VPC used for the runner and runner workers. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_runner_agent_role_arn"></a> [runner\_agent\_role\_arn](#output\_runner\_agent\_role\_arn) | ARN of the role used for the ec2 instance for the GitLab runner agent. |
| <a name="output_runner_agent_role_name"></a> [runner\_agent\_role\_name](#output\_runner\_agent\_role\_name) | Name of the role used for the ec2 instance for the GitLab runner agent. |
| <a name="output_runner_agent_sg_id"></a> [runner\_agent\_sg\_id](#output\_runner\_agent\_sg\_id) | ID of the security group attached to the GitLab runner agent. |
| <a name="output_runner_as_group_name"></a> [runner\_as\_group\_name](#output\_runner\_as\_group\_name) | Name of the autoscaling group for the gitlab-runner instance |
| <a name="output_runner_cache_bucket_arn"></a> [runner\_cache\_bucket\_arn](#output\_runner\_cache\_bucket\_arn) | ARN of the S3 for the build cache. |
| <a name="output_runner_cache_bucket_name"></a> [runner\_cache\_bucket\_name](#output\_runner\_cache\_bucket\_name) | Name of the S3 for the build cache. |
| <a name="output_runner_config_toml_rendered"></a> [runner\_config\_toml\_rendered](#output\_runner\_config\_toml\_rendered) | The rendered config.toml given to the Runner Manager. |
| <a name="output_runner_eip"></a> [runner\_eip](#output\_runner\_eip) | EIP of the Gitlab Runner |
| <a name="output_runner_launch_template_name"></a> [runner\_launch\_template\_name](#output\_runner\_launch\_template\_name) | The name of the runner's launch template. |
| <a name="output_runner_role_arn"></a> [runner\_role\_arn](#output\_runner\_role\_arn) | ARN of the role used for the docker machine runners. |
| <a name="output_runner_role_name"></a> [runner\_role\_name](#output\_runner\_role\_name) | Name of the role used for the docker machine runners. |
| <a name="output_runner_sg_id"></a> [runner\_sg\_id](#output\_runner\_sg\_id) | ID of the security group attached to the docker machine runners. |
| <a name="output_runner_user_data"></a> [runner\_user\_data](#output\_runner\_user\_data) | (Deprecated) The user data of the Gitlab Runner Agent's launch template. Set `var.debug.output_runner_user_data_to_file` to true to write `user_data.sh`. |
<!-- END_TF_DOCS -->
<!-- markdownlint-enable -->
<!-- cSpell:enable -->
<!-- markdown-link-check-enable -->

[1]: https://img.shields.io/badge/renovate-enabled-brightgreen?logo=renovate

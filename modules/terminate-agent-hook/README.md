# terminate-instances module

Module for Termination Lifecycle Hook Lambda Function

This module is used __internally__ by the parent [_terraform\-aws\-gitlab\-runners_](../../README.md) module.

## Overview

The Lambda functions evaluates an EC2 instance tag called `gitlab-runner-parent-id`, set in the
[runner config](../../template/runner-config.tftpl) by the parent module's
[user data](../../template/gitlab-runner.tftpl). Runner instances created by the runner
will have this tag applied with the parent runner's instance ID. When the runner
in the ASG is terminated, the lifecycle hook triggers the Lambda to
terminate spawned runner instances with the matching parent tag and/or any "orphaned"
instances with no running parent runner.

See [issue #214](https://github.com/cattle-ops/terraform-aws-gitlab-runner/issues/214) for
discussion on the scenario this module addresses.

Furthermore, all spot requests which are still open are cancelled. Otherwise they might be fulfilled later but
without the creating instance running, these spot request are never terminated and costs incur. The problem here
is, that no tags are added to the spot request by the docker+machine driver and we can only guess which ones belong
to our module. The rule is, that parts of the Executor's name become part of the related SSH key which is in turn part
of the spot request.

## Usage

### Default Behavior - Package With the Module

The default behavior of the module is to build and package the Lambda function
when Terraform is ran.

This produces the `.zip` file under a `builds/` directory relative to where the
Terraform root module is from the source under [`lambda/`](lambda).

This example shows interacting with this module via the parent module's
input variables:

```terraform
module "runner" {
  source  = "cattle-ops/gitlab-runner/aws"

  asg_terminate_lifecycle_hook_create         = true

  ...
```

### Example

This example shows using the parent module with the lifecycle hook enable.

Note the `asg_terminate_lifecycle_hook_*` variables:

```terraform
module "runner" {
  source  = "cattle-ops/gitlab-runner/aws"

  aws_region                    = "eu-west-1"
  environment                   = "runners-test"
  runners_name                  = "runners-test"
  runners_gitlab_url            = "https://code.foo.org/"
  docker_machine_instance_type	= "t3.large"
  runners_request_spot_instance = false
  runners_machine_autoscaling   = var.runners_machine_autoscaling

  vpc_id                   = data.aws_vpc.current.id
  subnet_ids_gitlab_runner = [data.aws_subnet.runner_a.id, data.aws_subnet.runner_b.id]
  subnet_id_runners        = data.aws_subnet.runner.id

  asg_max_instance_lifetime                   = 604800
  asg_terminate_lifecycle_hook_create         = true

  permissions_boundary              = "FooOrg-Permissions-Boundary"
  runners_iam_instance_profile_name = "foo-gitlab-runner-profile"
  runner_iam_policy_arns            = [data.aws_iam_policy.sas_full_rights.arn]

  cache_bucket_prefix   = var.environment
  cache_shared          = true
  cache_expiration_days = 90

  gitlab_runner_registration_config = {
    registration_token = aws_ssm_parameter.gitlab_runner_registration_token.value
    tag_list           = var.runners_tag_list
    description        = var.runners_description
    locked_to_project  = "true"
    run_untagged       = "false"
    maximum_timeout    = "7200"
  }

  # Refer to https://docs.docker.com/machine/drivers/aws/#options
  # for 'docker_machine_options' settings with the AWS driver
  docker_machine_options = var.docker_machine_options

  # See https://github.com/cattle-ops/terraform-aws-gitlab-runner/issues/160
  executor_docker_additional_volumes = ["/certs/client"]

  tags = local.common_tags

}
```

<!-- markdownlint-disable -->
<!-- cSpell:disable -->
<!-- markdown-link-check-disable -->

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | n/a |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_lifecycle_hook.terminate_instances](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_lifecycle_hook) | resource |
| [aws_cloudwatch_event_rule.terminate_instances](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.terminate_instances](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_log_group.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_policy.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.spot_request_housekeeping](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.spot_request_housekeeping](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.terminate_runner_instances](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.current_version_triggers](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.unqualified_alias_triggers](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [archive_file.terminate_runner_instances_lambda](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_caller_identity.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.spot_request_housekeeping](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_asg_arn"></a> [asg\_arn](#input\_asg\_arn) | The ARN of the Auto Scaling Group to attach to. | `string` | n/a | yes |
| <a name="input_asg_name"></a> [asg\_name](#input\_asg\_name) | The name of the Auto Scaling Group to attach to. The 'environment' will be prefixed to this. | `string` | n/a | yes |
| <a name="input_cloudwatch_logging_retention_in_days"></a> [cloudwatch\_logging\_retention\_in\_days](#input\_cloudwatch\_logging\_retention\_in\_days) | The number of days to retain logs in CloudWatch. | `number` | `30` | no |
| <a name="input_enable_xray_tracing"></a> [enable\_xray\_tracing](#input\_enable\_xray\_tracing) | Enables X-Ray for debugging and analysis | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | A name that identifies the environment, used as a name prefix and for tagging. | `string` | n/a | yes |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | KMS key id to encrypt the resources, e.g. logs, lambda environment variables, ... | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The name of the Lambda function to create. The 'environment' will be prefixed to this. | `string` | n/a | yes |
| <a name="input_name_docker_machine_runners"></a> [name\_docker\_machine\_runners](#input\_name\_docker\_machine\_runners) | The `Name` tag of EC2 instances created by the runner agent. | `string` | n/a | yes |
| <a name="input_name_iam_objects"></a> [name\_iam\_objects](#input\_name\_iam\_objects) | The name to use for IAM resources - roles and policies. | `string` | `""` | no |
| <a name="input_role_permissions_boundary"></a> [role\_permissions\_boundary](#input\_role\_permissions\_boundary) | An optional IAM permissions boundary to use when creating IAM roles. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to resources. | `map(any)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_lambda_function_arn"></a> [lambda\_function\_arn](#output\_lambda\_function\_arn) | Lambda function arn. |
| <a name="output_lambda_function_invoke_arn"></a> [lambda\_function\_invoke\_arn](#output\_lambda\_function\_invoke\_arn) | Lambda function invoke arn. |
| <a name="output_lambda_function_name"></a> [lambda\_function\_name](#output\_lambda\_function\_name) | Lambda function name. |
| <a name="output_lambda_function_source_code_hash"></a> [lambda\_function\_source\_code\_hash](#output\_lambda\_function\_source\_code\_hash) | Lambda function source code hash. |
<!-- END_TF_DOCS -->

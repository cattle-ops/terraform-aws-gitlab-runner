# Example - Spot Runner - Public subnets

In this scenario the multiple runner agents can be created with different configuration by instantiating the module
multiple times. Runners will scale automatically based on configuration. The S3 cache can be shared cross runners by
managing the cache outside the module.

![runners-cache](https://github.com/cattle-ops/terraform-aws-gitlab-runner/raw/main/assets/images/runner-cache.png)

This examples shows:

  - Usages of public subnets.
  - Usages of multiple runner instances sharing a common cache.
  - Overrides for tag naming.
  - Registration via GitLab token.
  - Auto scaling using `docker+machine` executor.
  - Register runner as [protected](https://docs.gitlab.com/ee/ci/runners/configure_runners.html#prevent-runners-from-revealing-sensitive-information).

## Prerequisite

The Terraform version is managed using [tfenv](https://github.com/Zordrak/tfenv). If you are not using `tfenv` please
check `.terraform-version` for the tested version.

<!-- markdownlint-disable -->
<!-- cSpell:disable -->
<!-- markdown-link-check-disable -->

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.78.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.5.2 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.3 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.6.3 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | >= 4.0.6 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.78.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cache"></a> [cache](#module\_cache) | ../../modules/cache | n/a |
| <a name="module_runner"></a> [runner](#module\_runner) | ../../ | n/a |
| <a name="module_runner2"></a> [runner2](#module\_runner2) | ../../ | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | >= 5.16.0 |

## Resources

| Name | Type |
|------|------|
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region. | `string` | `"eu-west-1"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | A name that identifies the environment, will used as prefix and for tagging. | `string` | `"runner-public"` | no |
| <a name="input_gitlab_url"></a> [gitlab\_url](#input\_gitlab\_url) | URL of the gitlab instance to connect to. | `string` | `"https://gitlab.com"` | no |
| <a name="input_preregistered_runner_token_ssm_parameter_name"></a> [preregistered\_runner\_token\_ssm\_parameter\_name](#input\_preregistered\_runner\_token\_ssm\_parameter\_name) | The name of the SSM parameter to read the preregistered GitLab Runner token from. | `string` | n/a | yes |
| <a name="input_runner_name"></a> [runner\_name](#input\_runner\_name) | Name of the runner, will be used in the runner config.toml | `string` | `"public-auto"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->

# Example - Spot Runner - Private subnets

This is the previous default example. For this example you need to register the runner before running terraform and
provide the runner token. Since version 3+ the runner can register itself by providing the registration token. This
example is provided to showcase backwards compatibility.

## Prerequisite

The terraform version is managed using [tfenv](https://github.com/Zordrak/tfenv). If you are not using `tfenv` please
check `.terraform-version` for the tested version.

<!-- markdownlint-disable -->
<!-- cSpell:disable -->
<!-- markdown-link-check-disable -->

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 5.25.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | 2.4.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | 3.2.1 |
| <a name="requirement_random"></a> [random](#requirement\_random) | 3.5.1 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | 4.0.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.25.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_runner"></a> [runner](#module\_runner) | ../../ | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 5.1.2 |
| <a name="module_vpc_endpoints"></a> [vpc\_endpoints](#module\_vpc\_endpoints) | terraform-aws-modules/vpc/aws//modules/vpc-endpoints | 5.1.2 |

## Resources

| Name | Type |
|------|------|
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/5.25.0/docs/data-sources/availability_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region. | `string` | `"eu-west-1"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | A name that identifies the environment, will used as prefix and for tagging. | `string` | `"ci-runners"` | no |
| <a name="input_gitlab_url"></a> [gitlab\_url](#input\_gitlab\_url) | URL of the gitlab instance to connect to. | `string` | n/a | yes |
| <a name="input_runner_name"></a> [runner\_name](#input\_runner\_name) | Name of the runner, will be used in the runner config.toml | `string` | n/a | yes |
| <a name="input_runner_token"></a> [runner\_token](#input\_runner\_token) | Token for the runner, will be used in the runner config.toml | `string` | n/a | yes |
| <a name="input_timezone"></a> [timezone](#input\_timezone) | Timezone that will be set for the runner. | `string` | `"Europe/Amsterdam"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->

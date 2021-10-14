# Example - Spot Runner - Private subnets

This is the previous default example. For this example you need to register the runner before running terraform and provide the runner token. Since version 3+ the runner can register itself by providing the registration token. This example is provided to showcase backwards compatibility.

## Prerequisite

The terraform version is managed using [tfenv](https://github.com/Zordrak/tfenv). If you are not using `tfenv` please check `.terraform-version` for the tested version.

## Providers

| Name | Version |
|------|---------|
| aws | 2.52 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| aws\_region | AWS region. | `string` | `"eu-west-1"` | no |
| environment | A name that identifies the environment, will used as prefix and for tagging. | `string` | `"ci-runners"` | no |
| gitlab\_url | URL of the gitlab instance to connect to. | `string` | n/a | yes |
| runner\_name | Name of the runner, will be used in the runner config.toml | `string` | n/a | yes |
| runner\_token | Token for the runner, will be used in the runner config.toml | `string` | n/a | yes |
| timezone | Name of the timezone that the runner will be used in. | `string` | `"Europe/Amsterdam"` | no |

## Outputs

No output.

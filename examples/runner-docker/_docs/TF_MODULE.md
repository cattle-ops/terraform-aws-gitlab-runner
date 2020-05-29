## Providers

| Name | Version |
|------|---------|
| aws | 2.56 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| aws\_region | AWS region. | `string` | `"eu-west-1"` | no |
| environment | A name that identifies the environment, will used as prefix and for tagging. | `string` | `"runners-docker"` | no |
| gitlab\_url | URL of the gitlab instance to connect to. | `string` | `"https://gitlab.com"` | no |
| registration\_token | n/a | `any` | n/a | yes |
| runner\_name | Name of the runner, will be used in the runner config.toml | `string` | `"docker"` | no |

## Outputs

No output.


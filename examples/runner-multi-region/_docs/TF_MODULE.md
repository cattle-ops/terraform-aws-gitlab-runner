## Providers

| Name | Version |
|------|---------|
| aws | 2.56 |
| local | 1.4 |
| null | 2.1.2 |
| tls | 2.1.1 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| aws\_region | AWS region. | `string` | `"eu-west-1"` | no |
| environment | A name that identifies the environment, will used as prefix and for tagging. | `string` | `"runner-public"` | no |
| gitlab\_url | URL of the gitlab instance to connect to. | `string` | `"https://gitlab.com"` | no |
| private\_ssh\_key\_filename | n/a | `string` | `"generated/id_rsa"` | no |
| public\_ssh\_key\_filename | n/a | `string` | `"generated/id_rsa.pub"` | no |
| registration\_token | n/a | `any` | n/a | yes |
| runner\_name | Name of the runner, will be used in the runner config.toml | `string` | `"public-auto"` | no |

## Outputs

No output.


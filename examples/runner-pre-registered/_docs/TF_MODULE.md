## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| aws\_region | AWS region. | string | `"eu-west-1"` | no |
| environment | A name that identifies the environment, will used as prefix and for tagging. | string | `"ci-runners"` | no |
| gitlab\_url | URL of the gitlab instance to connect to. | string | n/a | yes |
| private\_ssh\_key\_filename |  | string | `"generated/id_rsa"` | no |
| public\_ssh\_key\_filename |  | string | `"generated/id_rsa.pub"` | no |
| runner\_name | Name of the runner, will be used in the runner config.toml | string | n/a | yes |
| runner\_token | Token for the runner, will be used in the runner config.toml | string | n/a | yes |
| timezone | Name of the timezone that the runner will be used in. | string | `"Europe/Amsterdam"` | no |


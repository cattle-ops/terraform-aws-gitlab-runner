## Providers

| Name | Version |
|------|---------|
| aws | >= 2.46 |
| local | >= 1.4 |
| null | >= 2 |
| tls | >= 2 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| environment | Name of the environment (aka namespace) to ensure resources are unique. | `string` | n/a | yes |
| name | Name of the key, will be prefixed by the environment name. | `string` | n/a | yes |
| private\_ssh\_key\_filename | Filename (full path) for the private key. | `string` | `"./generated/id_rsa"` | no |
| public\_ssh\_key\_filename | Filename (full path) for the public key. | `string` | `"./generated/id_rsa.pub"` | no |
| rsa\_bits | n/a | `string` | `4048` | no |
| tags | Map of tags that will be added to created resources. By default resources will be tagged with name and environment. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| key\_pair | Generated key pair. |


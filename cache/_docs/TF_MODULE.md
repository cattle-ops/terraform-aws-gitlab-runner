## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| cache\_bucket\_name\_include\_account\_id | Boolean to add current account ID to cache bucket name. | bool | `"true"` | no |
| cache\_bucket\_prefix | Prefix for s3 cache bucket name. | string | `""` | no |
| cache\_bucket\_versioning | Boolean used to enable versioning on the cache bucket, false by default. | string | `"false"` | no |
| cache\_expiration\_days | Number of days before cache objects expires. | number | `"1"` | no |
| create\_cache\_bucket | This module is by default included in the runner module. To disable the creation of the bucket this parameter can be disabled. | string | `"true"` | no |
| environment | A name that identifies the environment, used as prefix and for tagging. | string | n/a | yes |
| tags | Map of tags that will be added to created resources. By default resources will be tagged with name and environment. | map(string) | `<map>` | no |

## Outputs

| Name | Description |
|------|-------------|
| arn | The ARN of the created bucket. |
| bucket | Name of the created bucket. |
| policy\_arn | Policy for users of the cache (bucket). |


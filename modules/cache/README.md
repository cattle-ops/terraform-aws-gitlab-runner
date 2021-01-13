# Cache module

This sub module creates an S3 bucket for build caches. The cache will have by default a life cycle policy the module will create a policy that can be used to access the cache.

## Usages

```

module "cache" {
  source      = "https://github.com/npalm/terraform-aws-gitlab-runner/tree/move-cache-to-moudle/cache"
  environment = "cache"
}

module "runner" {
  source  = "npalm/gitlab-runner/aws"

  ...

  cache_bucket = {
    create = false
    policy = "${module.cache.policy_arn}"
    bucket = "${module.cache.bucket}"
  }

}
```
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12 |

## Providers

| Name | Version |
|------|---------|
| aws | n/a |
| random | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| arn\_format | ARN format to be used. May be changed to support deployment in GovCloud/China regions. | `string` | `"arn:aws"` | no |
| cache\_bucket\_name\_include\_account\_id | Boolean to add current account ID to cache bucket name. | `bool` | `true` | no |
| cache\_bucket\_prefix | Prefix for s3 cache bucket name. | `string` | `""` | no |
| cache\_bucket\_set\_random\_suffix | Random string suffix for s3 cache bucket | `bool` | `false` | no |
| cache\_bucket\_versioning | Boolean used to enable versioning on the cache bucket, false by default. | `string` | `"false"` | no |
| cache\_expiration\_days | Number of days before cache objects expires. | `number` | `1` | no |
| cache\_lifecycle\_clear | Enable the rule to cleanup the cache for expired objects. | `bool` | `true` | no |
| cache\_lifecycle\_prefix | Object key prefix identifying one or more objects to which the clean up rule applies. | `string` | `"runner/"` | no |
| create\_cache\_bucket | This module is by default included in the runner module. To disable the creation of the bucket this parameter can be disabled. | `bool` | `true` | no |
| environment | A name that identifies the environment, used as prefix and for tagging. | `string` | n/a | yes |
| tags | Map of tags that will be added to created resources. By default resources will be tagged with name and environment. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| arn | The ARN of the created bucket. |
| bucket | Name of the created bucket. |
| policy\_arn | Policy for users of the cache (bucket). |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

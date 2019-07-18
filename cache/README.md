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

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| cache\_bucket\_prefix | Prefix for s3 cache bucket name. | string | `""` | no |
| cache\_bucket\_versioning | Boolean used to enable versioning on the cache bucket, false by default. | string | `"false"` | no |
| cache\_expiration\_days | Number of days before cache objects expires. | string | `"1"` | no |
| create\_cache\_bucket | This module is by default included in the runner module. To disable the creation of the bucket this paramter can be disabled. | string | `"true"` | no |
| environment | A name that identifies the environment, used as prefix and for tagging. | string | n/a | yes |
| tags | Map of tags that will be added to created resources. By default resources will be tagged with name and environment. | map(string) | `<map>` | no |

## Outputs

| Name | Description |
|------|-------------|
| arn | The ARN of the created bucket. |
| bucket | Name of the created bucket. |
| policy\_arn | Policy for users of the cache (bucket). |

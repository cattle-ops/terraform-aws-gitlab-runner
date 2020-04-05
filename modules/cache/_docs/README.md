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

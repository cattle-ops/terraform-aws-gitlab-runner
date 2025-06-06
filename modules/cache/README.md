# Cache module

This sub module creates an S3 bucket for build caches. The cache will have by default a life cycle policy the module
will create a policy that can be used to access the cache.

## Usages

```hcl
module "cache" {
  source      = "https://github.com/cattle-ops/terraform-aws-gitlab-runner/tree/move-cache-to-moudle/cache"
  environment = "cache"
}

module "runner" {
  source  = "cattle-ops/gitlab-runner/aws"

  ...

  cache_bucket = {
    create = false
    policy = "${module.cache.policy_arn}"
    bucket = "${module.cache.bucket}"
  }

}
```

<!-- markdownlint-disable -->
<!-- cSpell:disable -->
<!-- markdown-link-check-disable -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.docker_machine_cache](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_s3_bucket.build_cache](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.build_cache_versioning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.build_cache](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_public_access_block.build_cache_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.build_cache_encryption](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.build_cache_versioning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [random_string.s3_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.docker_machine_cache_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_arn_format"></a> [arn\_format](#input\_arn\_format) | ARN format to be used. May be changed to support deployment in GovCloud/China regions. | `string` | `"arn:aws"` | no |
| <a name="input_cache_bucket_name_include_account_id"></a> [cache\_bucket\_name\_include\_account\_id](#input\_cache\_bucket\_name\_include\_account\_id) | Boolean to add current account ID to cache bucket name. | `bool` | `true` | no |
| <a name="input_cache_bucket_policy"></a> [cache\_bucket\_policy](#input\_cache\_bucket\_policy) | JSON formatted policy document that controls access to S3 Bucket. | `string` | `null` | no |
| <a name="input_cache_bucket_prefix"></a> [cache\_bucket\_prefix](#input\_cache\_bucket\_prefix) | Prefix for s3 cache bucket name. | `string` | `""` | no |
| <a name="input_cache_bucket_set_random_suffix"></a> [cache\_bucket\_set\_random\_suffix](#input\_cache\_bucket\_set\_random\_suffix) | Random string suffix for s3 cache bucket | `bool` | `false` | no |
| <a name="input_cache_bucket_versioning"></a> [cache\_bucket\_versioning](#input\_cache\_bucket\_versioning) | Boolean used to enable versioning on the cache bucket, false by default. | `bool` | `false` | no |
| <a name="input_cache_expiration_days"></a> [cache\_expiration\_days](#input\_cache\_expiration\_days) | Number of days before cache objects expires. | `number` | `1` | no |
| <a name="input_cache_lifecycle_clear"></a> [cache\_lifecycle\_clear](#input\_cache\_lifecycle\_clear) | Enable the rule to cleanup the cache for expired objects. | `bool` | `true` | no |
| <a name="input_cache_lifecycle_prefix"></a> [cache\_lifecycle\_prefix](#input\_cache\_lifecycle\_prefix) | Object key prefix identifying one or more objects to which the clean up rule applies. | `string` | `"runner/"` | no |
| <a name="input_cache_logging_bucket"></a> [cache\_logging\_bucket](#input\_cache\_logging\_bucket) | S3 Bucket ID where the access logs to the cache bucket are stored. | `string` | `null` | no |
| <a name="input_cache_logging_bucket_prefix"></a> [cache\_logging\_bucket\_prefix](#input\_cache\_logging\_bucket\_prefix) | Prefix within the `cache_logging_bucket`. | `string` | `null` | no |
| <a name="input_create_aws_s3_bucket_public_access_block"></a> [create\_aws\_s3\_bucket\_public\_access\_block](#input\_create\_aws\_s3\_bucket\_public\_access\_block) | Enable the creation of the public access block for the cache bucket. | `bool` | `true` | no |
| <a name="input_create_cache_bucket"></a> [create\_cache\_bucket](#input\_create\_cache\_bucket) | (deprecated) If the cache should not be created, remove the whole module call! | `bool` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | A name that identifies the environment, used as prefix and for tagging. | `string` | n/a | yes |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | KMS key id to encrypted the resources. Ensure that your Runner/Executor has access to the KMS key. | `string` | `""` | no |
| <a name="input_name_iam_objects"></a> [name\_iam\_objects](#input\_name\_iam\_objects) | Set the name prefix of all AWS IAM resources created by this module | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags that will be added to created resources. By default resources will be tagged with name and environment. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | The ARN of the created bucket. |
| <a name="output_bucket"></a> [bucket](#output\_bucket) | Name of the created bucket. |
| <a name="output_policy_arn"></a> [policy\_arn](#output\_policy\_arn) | Policy for users of the cache (bucket). |
<!-- END_TF_DOCS -->

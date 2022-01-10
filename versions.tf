/* Providers used:
     aws:              the default provider which is also used to create the Gitlab Runner
     aws.cache_bucket: a provider to create the S3 cache bucket in another region.
*/
terraform {
  required_version = ">= 0.13.0"

  required_providers {
    aws = {
      version = ">= 3.35.0"
      source  = "hashicorp/aws"

      configuration_aliases = [cache_bucket]
    }

    null = {
      source = "hashicorp/null"
    }
  }
}

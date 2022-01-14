/* Providers used:
     aws:              the default provider which is also used to create the Gitlab Runner
     aws.cache_bucket: a provider to create the S3 cache bucket in another region.
*/
terraform {
  required_version = ">= 0.15"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.35.0"

      configuration_aliases = [aws.cache_bucket]
    }
  }
}

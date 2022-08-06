/* Providers used:
     aws:              the default provider which is also used to create the Gitlab Runner
     aws.cache_bucket: a provider to create the S3 cache bucket in another region.
*/
terraform {
  required_version = ">= 1"

  required_providers {
    aws = {
      version = "~> 4"
      source  = "hashicorp/aws"

      configuration_aliases = [aws.cache_bucket]
    }
  }
}
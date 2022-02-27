/* Providers used:
     aws:              the default provider which is also used to create the Gitlab Runner
     aws.cache_bucket: a provider to create the S3 cache bucket in another region.
*/
terraform {
  required_version = ">= 0.15.0"

  required_providers {
    aws = {
      version = "~> 3.35"
      source  = "hashicorp/aws"

      configuration_aliases = [aws.cache_bucket]
    }

    null = {
      source = "hashicorp/null"
    }
  }
}

provider "aws" {
  alias  = "cache_bucket"
  region = "eu-central-1"
}
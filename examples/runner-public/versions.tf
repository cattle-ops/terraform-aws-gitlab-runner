/* Providers used:
     aws:              the default provider which is also used to create the Gitlab Runner
     aws.cache_bucket: a provider to create the S3 cache bucket in another region.
*/
terraform {
  required_version = ">= 1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.7"

      configuration_aliases = [aws.cache_bucket]
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

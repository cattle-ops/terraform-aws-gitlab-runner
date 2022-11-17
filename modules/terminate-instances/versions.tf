terraform {
  required_version = ">= 1"

  required_providers {
    aws = {
      version = ">= 4"
      source  = "hashicorp/aws"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "2.2.0"
    }
  }
}

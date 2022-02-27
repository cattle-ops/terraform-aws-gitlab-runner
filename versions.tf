terraform {
  required_version = ">= 0.15.0"

  required_providers {
    aws = {
      version = "~> 3.35"
      source  = "hashicorp/aws"
    }

    null = {
      source = "hashicorp/null"
    }
  }
}

terraform {
  required_version = ">= 0.13.0"

  required_providers {
    aws = {
      version = ">= 3.35.0"
      source  = "hashicorp/aws"
    }

    null = {
      source = "hashicorp/null"
    }
  }
}

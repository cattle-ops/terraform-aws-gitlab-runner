terraform {
  required_version = ">= 1"

  required_providers {
    aws = {
      version = ">= 5.76"
      source  = "hashicorp/aws"
    }
  }
}

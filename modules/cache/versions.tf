terraform {
  required_version = ">= 1"

  required_providers {
    aws = {
      version = ">= 4"
      source  = "hashicorp/aws"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
  }
}

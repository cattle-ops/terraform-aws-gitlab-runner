
terraform {
  required_version = ">= 0.13"

  required_providers {
    aws = {
      version = ">= 4.0"
      source  = "hashicorp/aws"
    }
  }
}

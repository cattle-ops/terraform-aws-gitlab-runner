terraform {
  required_version = ">= 1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4"
    }
    local = {
      source = "hashicorp/local"
      version = ">= 2.4.0"
    }
  }
}

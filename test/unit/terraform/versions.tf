
terraform {
  required_version = ">= 1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.11"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.4.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "3"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.0"
    }
  }
}


terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.78.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.5.2"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.3"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.6"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.3"
    }
  }
}

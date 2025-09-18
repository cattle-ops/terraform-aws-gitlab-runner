terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 3"
    }
  }
}

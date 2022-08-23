terraform {
  required_version = ">= 1"

  experiments = [module_variable_optional_attrs]

  required_providers {
    aws = {
      version = "~> 4"
      source  = "hashicorp/aws"
    }
  }
}

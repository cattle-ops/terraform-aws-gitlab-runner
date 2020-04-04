terraform {
  required_version = "~> 0.12"
  required_providers {
    aws   = ">= 2.46"
    local = ">= 1.4"
    tls   = ">= 2"
    null  = ">= 2"
  }
}

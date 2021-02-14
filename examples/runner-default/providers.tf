provider "aws" {
  region = var.aws_region
}

provider "local" {}

provider "null" {}

provider "tls" {}

provider "random" {}

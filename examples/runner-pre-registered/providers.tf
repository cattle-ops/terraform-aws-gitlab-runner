provider "aws" {
  region  = var.aws_region
  version = "2.18"
}

provider "template" {
  version = "2.1.2"
}

provider "local" {
  version = "1.2.2"
}

provider "null" {
  version = "2.1.2"
}

provider "tls" {
  version = "2.0.1"
}


provider "aws" {
  region  = var.aws_region
  version = "~> 3.23.0"
}

provider "local" {
  version = "1.4"
}

provider "null" {
  version = "~> 3.0.0"
}

provider "tls" {
  version = "2.2.0"
}

provider "random" {
  version = "~> 3.0.1"
}

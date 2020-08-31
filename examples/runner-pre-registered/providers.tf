provider "aws" {
  region  = var.aws_region
  version = "2.68"
}

provider "local" {
  version = "1.4"
}

provider "null" {
  version = "2.1.2"
}

provider "tls" {
  version = "2.2.0"
}

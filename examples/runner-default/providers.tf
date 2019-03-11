provider "aws" {
  region  = "${var.aws_region}"
  version = "2.2"
}

provider "template" {
  version = "2.1"
}

provider "local" {
  version = "1.1"
}

provider "null" {
  version = "2.1"
}

provider "tls" {
  version = "1.2"
}

provider "http" {
  version = "1.0"
}

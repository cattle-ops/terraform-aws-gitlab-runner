provider "aws" {
  region = var.aws_main_region
}

provider "aws" {
  region = var.aws_alternate_region
  alias  = "alternate_region"
}

provider "local" {}

provider "null" {}

provider "tls" {}

provider "random" {}

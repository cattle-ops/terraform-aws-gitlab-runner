provider "aws" {
  region  = "${var.aws_region}"
  version = "1.23"
}

provider "template" {
  version = "1.0"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "1.5.1"

  name = "vpc-${var.environment}"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true

  tags = {
    Environment = "${var.environment}"
  }
}

module "runner" {
  source = "../../"

  aws_region     = "${var.aws_region}"
  environment    = "${var.environment}"
  ssh_public_key = "${file("${var.ssh_key_file}")}"

  vpc_id                  = "${module.vpc.vpc_id}"
  subnet_id_gitlab_runner = "${element(module.vpc.private_subnets, 0)}"
  subnet_id_runners       = "${element(module.vpc.private_subnets, 0)}"

  runners_name       = "${var.runner_name}"
  runners_gitlab_url = "${var.gitlab_url}"
  runners_token      = "${var.runner_token}"
}

provider "aws" {
  region  = "${var.aws_region}"
  version = "1.3.1"
}

provider "template" {
  version = "1.0"
}

module "vpc" {
  source = "git::https://github.com/npalm/tf-aws-vpc.git?ref=1.0.0"

  aws_region  = "${var.aws_region}"
  environment = "${var.environment}"

  create_private_hosted_zone = "true"
  create_private_subnets     = "true"

  availability_zones = {
    us-east-1 = ["us-east-1a"]
    eu-west-1 = ["eu-west-1a"]
  }
}

module "runner" {
  source = "../"

  aws_region       = "${var.aws_region}"
  environment      = "${var.environment}"
  ssh_key_file_pub = "${var.ssh_key_file}"

  vpc_id                  = "${module.vpc.vpc_id}"
  subnet_id_gitlab_runner = "${element(module.vpc.private_subnets, 0)}"
  subnet_id_runners       = "${element(module.vpc.private_subnets, 0)}"

  runner_name       = "${var.runner_name}"
  runner_gitlab_url = "${var.gitlab_url}"
  runner_token      = "${var.runner_token}"
}

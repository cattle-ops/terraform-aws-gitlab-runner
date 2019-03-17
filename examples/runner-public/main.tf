module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "1.59.0"

  name = "vpc-${var.environment}"
  cidr = "10.1.0.0/16"

  azs            = ["eu-west-1b"]
  public_subnets = ["10.1.101.0/24"]

  tags = {
    Environment = "${var.environment}"
  }
}

data "http" "ip" {
  url = "http://ipv4.icanhazip.com"
}

locals {
  #   callers_ip                  =
  # any_any_cidr_block          = ["0.0.0.0/0"]
  # specified_cidr_blocks       = "${concat(local.callers_ip, var.specified_cidr_blocks)}"
  # cidr_blocks_allowed_inbound = "${split(",", var.allow_all_inbound ? join(",", local.any_any_cidr_block) : join(",", local.specified_cidr_blocks))}"
  cidr_blocks_allowed_inbound = ["${chomp(data.http.ip.body)}/32"]
}

module "runner" {
  source = "../../"

  aws_region  = "${var.aws_region}"
  environment = "${var.environment}"

  ssh_key_name = "${aws_key_pair.this.key_name}"

  runners_use_private_address = false

  vpc_id                   = "${module.vpc.vpc_id}"
  subnet_ids_gitlab_runner = "${module.vpc.public_subnets}"
  subnet_id_runners        = "${element(module.vpc.public_subnets, 0)}"
  aws_zone                 = "b"

  cidr_blocks_allowed_inbound = ["${local.cidr_blocks_allowed_inbound}"]
  runners_name                = "${var.runner_name}"
  runners_gitlab_url          = "${var.gitlab_url}"

  gitlab_runner_registration_config = {
    registration_token = "ReEdqkFQ-UNzjozA63EC"
    tag_list           = "docker.m3"
    description        = "auto register"
    locked_to_project  = "true"
    run_untagged       = "false"
    maximum_timeout    = "3600"
  }
}

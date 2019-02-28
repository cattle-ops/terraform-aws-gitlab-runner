module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "1.37.0"

  name = "vpc-${var.environment}"
  cidr = "10.1.0.0/16"

  azs            = ["eu-west-1a"]
  public_subnets = ["10.1.101.0/24"]

  tags = {
    Environment = "${var.environment}"
  }
}

module "runner" {
  source = "../../"

  aws_region  = "${var.aws_region}"
  environment = "${var.environment}"

  ssh_public_key = "${local_file.public_ssh_key.content}"

  runners_use_private_address = false

  vpc_id                   = "${module.vpc.vpc_id}"
  subnet_ids_gitlab_runner = "${module.vpc.public_subnets}"
  subnet_id_runners        = "${element(module.vpc.public_subnets, 0)}"

  runners_name       = "${var.runner_name}"
  runners_gitlab_url = "${var.gitlab_url}"
  runners_token      = "${var.runner_token}"
}

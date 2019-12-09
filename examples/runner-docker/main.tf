data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "1.66.0"

  name = "vpc-${var.environment}"
  cidr = "10.1.0.0/16"

  azs                = ["${data.aws_availability_zones.available.names[0]}"]
  public_subnets     = ["10.1.101.0/24"]
  enable_s3_endpoint = true

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

  runners_executor   = "docker"
  runners_name       = "${var.runner_name}"
  runners_gitlab_url = "${var.gitlab_url}"

  gitlab_runner_registration_config = {
    registration_token = "${var.registration_token}"
    tag_list           = "docker_runner"
    description        = "runner docker - auto"
    locked_to_project  = "true"
    run_untagged       = "false"
    maximum_timeout    = "3600"
  }

  enable_eip = "true"
}

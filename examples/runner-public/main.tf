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

  vpc_id                  = "${module.vpc.vpc_id}"
  subnet_id_gitlab_runner = "${element(module.vpc.public_subnets, 0)}"
  subnet_id_runners       = "${element(module.vpc.public_subnets, 0)}"

  runners_name       = "${var.runner_name}"
  runners_gitlab_url = "${var.gitlab_url}"
  runners_token      = "${var.runner_token}"

  runners_off_peak_timezone   = "Europe/Amsterdam"
  runners_off_peak_idle_count = 0
  runners_off_peak_idle_time  = 60

  # working 9 to 5 :)
  runners_off_peak_periods = "[\"* * 0-9,17-23 * * mon-fri *\", \"* * * * * sat,sun *\"]"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "1.60.0"

  name = "vpc-${var.environment}"
  cidr = "10.1.0.0/16"

  azs            = ["eu-west-1b"]
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
  aws_zone                 = "b"

  runner_instance_spot_price = "0.006"

  runners_name             = "${var.runner_name}"
  runners_gitlab_url       = "${var.gitlab_url}"
  runners_environment_vars = ["KEY=Value", "FOO=bar"]

  gitlab_runner_registration_config = {
    registration_token = "${var.registration_token}"
    tag_list           = "docker_spot_runner"
    description        = "runner public - auto"
    locked_to_project  = "true"
    run_untagged       = "false"
    maximum_timeout    = "3600"
  }

  overrides = {
    name_sg                     = "my-security-group"
    name_runner_agent_instance  = "my-runner-agent"
    name_docker_machine_runners = "my-runners-dm"
  }
}

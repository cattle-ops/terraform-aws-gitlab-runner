data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.70"

  name = "vpc-${var.environment}"
  cidr = "10.1.0.0/16"

  azs            = [data.aws_availability_zones.available.names[0]]
  public_subnets = ["10.1.101.0/24"]

  map_public_ip_on_launch = "false"

  tags = {
    Environment = var.environment
  }
}

module "cache" {
  source      = "../../modules/cache"
  environment = var.environment
}

module "runner" {
  source = "../../"

  aws_region  = var.aws_region
  environment = var.environment

  runners_use_private_address = false

  vpc_id    = module.vpc.vpc_id
  subnet_id = element(module.vpc.public_subnets, 0)

  docker_machine_spot_price_bid = "on-demand-price"

  runners_name             = var.runner_name
  runners_gitlab_url       = var.gitlab_url
  runners_environment_vars = ["KEY=Value", "FOO=bar"]

  runners_privileged         = "false"
  runners_additional_volumes = ["/var/run/docker.sock:/var/run/docker.sock"]

  gitlab_runner_registration_config = {
    registration_token = var.registration_token
    tag_list           = "docker_spot_runner"
    description        = "runner public - auto"
    locked_to_project  = "true"
    run_untagged       = "false"
    maximum_timeout    = "3600"
    access_level       = "ref_protected"
  }

  overrides = {
    name_sg                     = "my-security-group"
    name_runner_agent_instance  = "my-runner-agent"
    name_docker_machine_runners = "my-runners-dm"
  }

  cache_shared = "true"

  cache_bucket = {
    create = false
    policy = "${module.cache.policy_arn}"
    bucket = "${module.cache.bucket}"
  }
}

module "runner2" {
  source = "../../"

  aws_region  = var.aws_region
  environment = "${var.environment}-2"

  runners_use_private_address = false

  vpc_id                   = module.vpc.vpc_id
  subnet_ids_gitlab_runner = module.vpc.public_subnets
  subnet_id_runners        = element(module.vpc.public_subnets, 0)

  docker_machine_spot_price_bid = "on-demand-price"

  runners_name       = var.runner_name
  runners_gitlab_url = var.gitlab_url

  gitlab_runner_registration_config = {
    registration_token = var.registration_token
    tag_list           = "docker_spot_runner_2"
    description        = "runner public - auto"
    locked_to_project  = "true"
    run_untagged       = "false"
    maximum_timeout    = "3600"
  }

  cache_shared = "true"

  cache_bucket = {
    create = false
    policy = "${module.cache.policy_arn}"
    bucket = "${module.cache.bucket}"
  }
}

resource "null_resource" "cancel_spot_requests" {
  # Cancel active and open spot requests, terminate instances
  triggers = {
    environment = var.environment
  }

  provisioner "local-exec" {
    when    = destroy
    command = "../../bin/cancel-spot-instances.sh ${self.triggers.environment}"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Every VPC resource should have an associated Flow Log: This is an example only. No flow logs are created.
# kics-scan ignore-line
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.2.0"

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

  vpc_id      = module.vpc.vpc_id
  subnet_id   = element(module.vpc.public_subnets, 0)
  environment = var.environment

  security_group_prefix = "my-security-group"

  runner_instance = {
    name        = var.runner_name
    name_prefix = "my-runner-agent"
  }

  runner_gitlab = {
    url = var.gitlab_url
  }

  runner_gitlab_registration_config = {
    registration_token = var.registration_token
    tag_list           = "docker_spot_runner"
    description        = "runner public - auto"
    locked_to_project  = "true"
    run_untagged       = "false"
    maximum_timeout    = "3600"
    access_level       = "ref_protected"
  }

  runner_worker = {
    environment_variables = ["KEY=Value", "FOO=bar"]
  }

  runner_worker_cache = {
    shared = "true"
    create = false
    policy = module.cache.policy_arn
    bucket = module.cache.bucket
  }

  runner_worker_docker_options = {
    privileged = "false"
    volumes    = ["/cache", "/var/run/docker.sock:/var/run/docker.sock"]
  }

  runner_worker_docker_machine_instance = {
    private_address_only = false
    name_prefix          = "my-runners-dm"
  }
}

module "runner2" {
  source = "../../"

  vpc_id      = module.vpc.vpc_id
  subnet_id   = element(module.vpc.public_subnets, 0)
  environment = "${var.environment}-2"

  runner_instance = {
    name = var.runner_name
  }

  runner_gitlab = {
    url = var.gitlab_url
  }

  runner_gitlab_registration_config = {
    registration_token = var.registration_token
    tag_list           = "docker_spot_runner_2"
    description        = "runner public - auto"
    locked_to_project  = "true"
    run_untagged       = "false"
    maximum_timeout    = "3600"
  }

  runner_worker_cache = {
    runner_worker_shared = "true"
    create               = false
    policy               = module.cache.policy_arn
    bucket               = module.cache.bucket
  }

  runner_worker_docker_machine_instance = {
    private_address_only = false
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Every VPC resource should have an associated Flow Log: This is an example only. No flow logs are created.
# kics-scan ignore-line
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"

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

  environment = var.environment

  executor_docker_machine_use_private_address = false

  vpc_id    = module.vpc.vpc_id
  subnet_id = element(module.vpc.public_subnets, 0)

  executor_docker_machine_ec2_spot_price_bid = "on-demand-price"

  agent_gitlab_runner_name                         = var.runner_name
  agent_gitlab_url                     = var.gitlab_url
  executor_extra_environment_variables = ["KEY=Value", "FOO=bar"]

  executor_docker_privileged                 = "false"
  executor_docker_additional_volumes = ["/var/run/docker.sock:/var/run/docker.sock"]

  agent_gitlab_registration_config = {
    registration_token = var.registration_token
    tag_list           = "docker_spot_runner"
    description        = "runner public - auto"
    locked_to_project  = "true"
    run_untagged       = "false"
    maximum_timeout    = "3600"
    access_level       = "ref_protected"
  }

  security_group_prefix                   = "my-security-group"
  agent_instance_prefix                   = "my-runner-agent"
  executor_docker_machine_instance_prefix = "my-runners-dm"

  executor_cache_shared = "true"

  executor_cache_s3_bucket = {
    create = false
    policy = module.cache.policy_arn
    bucket = module.cache.bucket
  }
}

module "runner2" {
  source = "../../"

  environment = "${var.environment}-2"

  executor_docker_machine_use_private_address = false

  vpc_id    = module.vpc.vpc_id
  subnet_id = element(module.vpc.public_subnets, 0)

  executor_docker_machine_ec2_spot_price_bid = "on-demand-price"

  agent_gitlab_runner_name     = var.runner_name
  agent_gitlab_url = var.gitlab_url

  agent_gitlab_registration_config = {
    registration_token = var.registration_token
    tag_list           = "docker_spot_runner_2"
    description        = "runner public - auto"
    locked_to_project  = "true"
    run_untagged       = "false"
    maximum_timeout    = "3600"
  }

  executor_cache_shared = "true"

  executor_cache_s3_bucket = {
    create = false
    policy = module.cache.policy_arn
    bucket = module.cache.bucket
  }
}

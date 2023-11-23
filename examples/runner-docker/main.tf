data "aws_availability_zones" "available" {
  state = "available"
}

# VPC Flow logs are not needed here
# kics-scan ignore-line
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.2.0"

  name = "vpc-${var.environment}"
  cidr = "10.1.0.0/16"

  azs                     = [data.aws_availability_zones.available.names[0]]
  public_subnets          = ["10.1.101.0/24"]
  map_public_ip_on_launch = false

  tags = {
    Environment = var.environment
  }
}

module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "5.2.0"

  vpc_id = module.vpc.vpc_id

  endpoints = {
    s3 = {
      service = "s3"
      tags    = { Name = "s3-vpc-endpoint" }
    }
  }

  tags = {
    Environment = var.environment
  }
}

module "runner" {
  source = "../../"

  vpc_id      = module.vpc.vpc_id
  subnet_id   = element(module.vpc.public_subnets, 0)
  environment = var.environment

  runner_instance = {
    runner_use_eip = true
    name           = var.runner_name
  }

  runner_networking = {
    security_group_description = "Custom description for gitlab-runner"
  }

  runner_gitlab = {
    url = var.gitlab_url
  }

  runner_gitlab_registration_config = {
    registration_token = var.registration_token
    tag_list           = "docker_runner"
    description        = "runner docker - auto"
    locked_to_project  = "true"
    run_untagged       = "false"
    maximum_timeout    = "3600"
  }

  runner_worker = {
    type = "docker"
  }

  runner_worker_docker_machine_instance = {
    private_address_only = false
  }

  runner_worker_docker_machine_security_group_description = "Custom description for docker-machine"
}

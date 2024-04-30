data "aws_availability_zones" "available" {
  state = "available"
}

# VPC Flow logs are not needed here
# kics-scan ignore-line
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

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
  version = "5.8.1"

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

    preregistered_runner_token_ssm_parameter_name = var.preregistered_runner_token_ssm_parameter_name
  }

  runner_worker = {
    type = "docker"
  }

  runner_worker_docker_machine_instance = {
    private_address_only = false
  }

  runner_worker_docker_machine_security_group_description = "Custom description for docker-machine"
}

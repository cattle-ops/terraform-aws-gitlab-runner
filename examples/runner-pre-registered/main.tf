data "aws_availability_zones" "available" {
  state = "available"
}

# VPC Flow logs are not needed here
# kics-scan ignore-line
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.2.0"

  name = "vpc-${var.environment}"
  cidr = "10.0.0.0/16"

  azs                     = [data.aws_availability_zones.available.names[0]]
  private_subnets         = ["10.0.1.0/24"]
  public_subnets          = ["10.0.101.0/24"]
  map_public_ip_on_launch = false

  enable_nat_gateway = true
  single_nat_gateway = true

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
  subnet_id   = element(module.vpc.private_subnets, 0)
  environment = var.environment

  runner_instance = {
    name = var.runner_name
  }

  runner_gitlab = {
    url                = var.gitlab_url
    registration_token = var.runner_token
  }

  # working 9 to 5 :)
  runner_worker_docker_machine_autoscaling_options = [
    {
      periods    = ["* * 0-9,17-23 * * mon-fri *", "* * * * * sat,sun *"]
      idle_count = 0
      idle_time  = 60
      timezone   = var.timezone
    }
  ]
}

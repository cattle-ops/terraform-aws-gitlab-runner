data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = module.vpc.vpc_id
}

# VPC Flow logs are not needed here
# kics-scan ignore-line
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = ">= 5.16.0"

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
  version = ">= 5.16.0"

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

  environment = var.environment

  vpc_id    = module.vpc.vpc_id
  subnet_id = element(module.vpc.private_subnets, 0)

  runner_instance = {
    collect_autoscaling_metrics = ["GroupDesiredCapacity", "GroupInServiceCapacity"]
    name                        = var.runner_name
    ssm_access                  = true
  }

  runner_networking = {
    allow_incoming_ping_security_group_ids = [data.aws_security_group.default.id]
  }

  runner_gitlab = {
    url = var.gitlab_url

    preregistered_runner_token_ssm_parameter_name = var.preregistered_runner_token_ssm_parameter_name
  }

  runner_worker = {
    type = "docker-autoscaler"
  }

  runner_worker_gitlab_pipeline = {
    pre_build_script  = <<EOT
        '''
        echo 'multiline 1'
        echo 'multiline 2'
        '''
        EOT
    post_build_script = "\"echo 'single line'\""
  }

  runner_worker_docker_autoscaler = {
    fleeting_plugin_version = "1.0.0"
  }

  runner_worker_docker_autoscaler_ami_owners = ["591542846629"] # FIXME Change to your AWS account ID
  runner_worker_docker_autoscaler_ami_filter = {
    name = ["al2023-ami-ecs-hvm-2023.0.20240723-kernel-6.1-x86_64"] # FIXME Change to your AMI name
  }

  runner_worker_docker_autoscaler_instance = {
    monitoring = true
  }

  runner_worker_docker_autoscaler_asg = {
    subnet_ids                               = module.vpc.private_subnets
    types                                    = ["t3a.micro", "t3a.small", "t3.micro", "t3.small"]
    enable_mixed_instances_policy            = true
    on_demand_base_capacity                  = 1
    on_demand_percentage_above_base_capacity = 0
    max_growth_rate                          = 10
  }

  runner_worker_docker_autoscaler_autoscaling_options = [
    {
      periods      = ["* * * * *"]
      timezone     = "Europe/Berlin"
      idle_count   = 0
      idle_time    = "0s"
      scale_factor = 2
    },
    {
      periods      = ["* 7-19 * * mon-fri"]
      timezone     = "Europe/Berlin"
      idle_count   = 3
      idle_time    = "30m"
      scale_factor = 2
    }
  ]

  runner_worker_docker_options = {
    volumes = ["/cache", "/var/run/docker.sock:/var/run/docker.sock"]
  }

  tags = {
    "tf-aws-gitlab-runner:example"           = "runner-default"
    "tf-aws-gitlab-runner:instancelifecycle" = "spot:yes"
  }
}

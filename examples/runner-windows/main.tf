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
    private_address_only        = false
  }

  runner_networking = {
    allow_incoming_ping_security_group_ids = [data.aws_security_group.default.id]
  }

  runner_gitlab = {
    url = var.gitlab_url

    preregistered_runner_token_ssm_parameter_name = var.preregistered_runner_token_ssm_parameter_name
  }

  runner_worker = {
    type            = "docker-autoscaler"
    max_jobs        = 10
    use_private_key = true

    environment_variables = [
      "FF_USE_POWERSHELL_PATH_RESOLVER=1"
    ]
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
    connector_config_user   = "Administrator"
  }

  runner_worker_docker_autoscaler_ami_owners = ["self"] # FIXME Leave to self or change to your AWS account ID
  runner_worker_docker_autoscaler_ami_id     = "<windows-ami-id>"

  runner_worker_docker_autoscaler_instance = {
    monitoring           = true
    private_address_only = false
  }

  runner_worker_docker_autoscaler_asg = {
    subnet_ids                    = module.vpc.private_subnets
    types                         = ["m6a.medium", "m6i.medium"] # FIXME change these to what best fits your needs, keeping in mind that Windows runners need bigger instances
    enable_mixed_instances_policy = true

    # FIXME These settings enable windows runners to scale down to zero if no jobs are running but you can change it to fit your needs
    on_demand_base_capacity                  = 0
    on_demand_percentage_above_base_capacity = 0
    max_growth_rate                          = 10
    spot_allocation_strategy                 = "price-capacity-optimized"
    spot_instance_pools                      = 0
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
    volumes    = ["C:/cache"]
    privileged = false
  }

  tags = {
    "tf-aws-gitlab-runner:example"           = "runner-default"
    "tf-aws-gitlab-runner:instancelifecycle" = "spot:yes"
  }
}

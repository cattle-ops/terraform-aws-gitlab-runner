data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = module.vpc.vpc_id
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.70"

  name = "vpc-${var.environment}"
  cidr = "10.0.0.0/16"

  azs             = [data.aws_availability_zones.available.names[0]]
  private_subnets = ["10.0.1.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_s3_endpoint = true

  tags = {
    Environment = var.environment
  }
}

module "runner" {
  source = "../../"

  aws_region  = var.aws_region
  environment = var.environment

  vpc_id                   = module.vpc.vpc_id
  subnet_ids_gitlab_runner = module.vpc.private_subnets
  subnet_id_runners        = element(module.vpc.private_subnets, 0)
  metrics_autoscaling      = ["GroupDesiredCapacity", "GroupInServiceCapacity"]

  runners_name             = var.runner_name
  runners_gitlab_url       = var.gitlab_url
  enable_runner_ssm_access = true

  gitlab_runner_security_group_ids = [data.aws_security_group.default.id]

  docker_machine_download_url   = "https://gitlab-docker-machine-downloads.s3.amazonaws.com/v0.16.2-gitlab.2/docker-machine"
  docker_machine_spot_price_bid = "on-demand-price"

  gitlab_runner_registration_config = {
    registration_token = var.registration_token
    tag_list           = "docker_spot_runner"
    description        = "runner default - auto"
    locked_to_project  = "true"
    run_untagged       = "false"
    maximum_timeout    = "3600"
  }

  tags = {
    "tf-aws-gitlab-runner:example"           = "runner-default"
    "tf-aws-gitlab-runner:instancelifecycle" = "spot:yes"
  }

  runners_privileged         = "true"
  runners_additional_volumes = ["/certs/client"]

  runners_volumes_tmpfs = [
    {
      volume  = "/var/opt/cache",
      options = "rw,noexec"
    }
  ]

  runners_services_volumes_tmpfs = [
    {
      volume  = "/var/lib/mysql",
      options = "rw,noexec"
    }
  ]

  # working 9 to 5 :)
  runners_machine_autoscaling = [
    {
      periods    = ["\"* * 0-9,17-23 * * mon-fri *\"", "\"* * * * * sat,sun *\""]
      idle_count = 0
      idle_time  = 60
      timezone   = var.timezone
    }
  ]

  runners_pre_build_script = <<EOT
  '''
  echo 'multiline 1'
  echo 'multiline 2'
  '''
  EOT

  runners_post_build_script = "\"echo 'single line'\""
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

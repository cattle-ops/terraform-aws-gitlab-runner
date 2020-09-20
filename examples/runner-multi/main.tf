data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = module.vpc.vpc_id
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.33"

  name = "vpc-${var.environment}"
  cidr = "10.0.0.0/16"

  azs             = [data.aws_availability_zones.available.names]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_s3_endpoint = true

  tags = {
    Environment = var.environment
  }
}

locals {
  subnet_ids     = tolist(module.vpc.public_subnets)
  instance_types = ["c5a.xlarge", "c5.xlarge", "m5a.xlarge", "m5.xlarge"]
}

module "gitlab_runner" {
  source = "../../"

  # CORE OF THIS EXAMPLE

  runners = [
    # Create a new runner for matrix of each subnet id and instance type
    for element in setproduct(local.subnet_ids, local.instance_types) : {
      subnet_id     = element[0]
      instance_type = element[1]
    }
  ]

  # BORING STUFF BELOW

  aws_region  = var.aws_region
  environment = var.environment

  # Network, logging, accessibility
  vpc_id                               = module.vpc.vpc_id
  subnet_ids_gitlab_runner             = local.subnet_ids
  subnet_id_runners                    = local.subnet_ids[0]
  metrics_autoscaling                  = ["GroupDesiredCapacity", "GroupInServiceCapacity"]
  enable_runner_ssm_access             = true
  enable_eip                           = true
  gitlab_runner_security_group_ids     = [data.aws_security_group.default.id]
  docker_machine_download_url          = "https://gitlab-docker-machine-downloads.s3.amazonaws.com/v0.16.2-gitlab.2/docker-machine"
  enable_docker_machine_ssm_access     = true
  cloudwatch_logging_retention_in_days = 7
  enable_cloudwatch_logging            = true

  # Cache
  cache_shared                         = true
  cache_bucket_versioning              = false
  cache_bucket_prefix                  = var.environment
  cache_bucket_name_include_account_id = false
  cache_expiration_days                = 30

  # Naming overrides
  overrides = {
    name_sg                     = ""
    name_runner_agent_instance  = "gitlab-agent"
    name_docker_machine_runners = "gitlab-worker"
  }

  # Registration
  gitlab_runner_registration_config = {
    registration_token = var.runner_token
    tag_list           = "docker,spot,aws,ec2"
    description        = "${var.environment} AWS GitLab Runner on Spot Instances"
    locked_to_project  = "false"
    run_untagged       = "false"
    maximum_timeout    = "3600"
  }

  tags = {
    "tf-aws-gitlab-runner:instancelifecycle" = "spot:yes"
  }

  runners_name       = var.environment
  runners_gitlab_url = var.gitlab_url

  runners_concurrent          = 20
  runners_root_size           = 16
  runners_max_builds          = 100
  runners_request_concurrency = 1
  runners_privileged          = true
  runners_image               = "docker:19.03.12"
  runners_pull_policy         = "if-not-present"

  runners_idle_count          = 0
  runners_idle_time           = 3600 # 1h
  runners_off_peak_idle_count = 0
  runners_off_peak_timezone   = var.timezone
  runners_off_peak_periods    = jsonencode(["* * 0-9,17-23 * * mon-fri *", "* * * * * sat,sun *"])
  runners_off_peak_idle_time  = 1800 # 30m

  runners_environment_vars = [
    "DOCKER_VERSION=19.03.12",
    "DOCKER_DRIVER=overlay2",
  ]

  runners_additional_volumes = [
    "/certs/client",
    "/builds:/builds:rw",
    "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt"
  ]

  runners_volumes_tmpfs = [
    {
      volume  = "/var/opt/cache",
      options = "rw,noexec"
    }
  ]

  docker_machine_options = [
    "engine-storage-driver=overlay2"
  ]
}

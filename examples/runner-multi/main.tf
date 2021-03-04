data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {}

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
  environment    = "example-runners"
  subnet_ids     = tolist(module.vpc.public_subnets)
  instance_types = ["c5a.xlarge", "c5.xlarge", "m5a.xlarge", "m5.xlarge"]
  vpc_id         = module.vpc.vpc_id
}

module "gitlab_runner" {
  source = "../../"

  # CORE OF THIS EXAMPLE

  aws_region  = "eu-central-1"
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
  cache_bucket_prefix                  = local.environment
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

  runners_pre_build_script = "update-ca-certificates --fresh > /dev/null; if docker -v; then docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY || echo \\\"We're most likely not able to connect to Docker. This is fine..\\\"; else echo \\\"Skipping Docker auth...\\\"; fi"

  runners_environment_vars = [
    "DOCKER_VERSION=19.03.12",
    "DOCKER_DRIVER=overlay2",
  ]

  runners_additional_volumes = [
    "/certs/client",
    "/builds:/builds:rw",
  ]

  runners_volumes_tmpfs = [
    {
      volume  = "/var/opt/cache",
      options = "rw,noexec"
    }
  ]

  userdata_pre_install = <<-SCRIPT
    # Configure Terraform Docker Machine Driver
    chmod +x /extra-files/docker-machine-terraform.sh
    /extra-files/docker-machine-terraform.sh
    (cd /extra-files/runners-config && terraform init && zip -r ../runners-config.zip .)
  SCRIPT


  post_reload_config = <<-SCRIPT
    (cd /extra-files/runners-config && terraform init && zip -r ../runners-config.zip .)
  SCRIPT

  docker_machine_options = [
    "terraform-config=/extra-files/runners-config.zip/",
    "terraform-variables-from=/extra-files/runners-vars.json",
    "engine-storage-driver=overlay2"
  ]

  extra_files = {
    "runners-config/main.tf"      = file("${path.module}/worker-config/main.tf")
    "runners-config/variables.tf" = file("${path.module}/worker-config/variables.tf")
    "runners-config/outputs.tf"   = file("${path.module}/worker-config/outputs.tf")
    "docker-machine-terraform.sh" = templatefile("${path.module}/docker-machine-terraform.sh", {
      terraform_url        = "https://releases.hashicorp.com/terraform/0.13.3/terraform_0.13.3_linux_amd64.zip"
      terraform_driver_url = "https://github.com/krzysztof-miemiec/docker-machine-driver-terraform/releases/download/v0.5.0/linux-amd64.zip"
    })
    "runners-vars.json" = jsonencode({
      ec2_name                    = "gitlab-worker"
      image_id                    = var.image_id
      instance_types              = local.instance_types
      region                      = data.aws_region.current.name
      subnets                     = local.subnet_ids
      security_group_ids          = [module.gitlab_runner.runner_sg_id]
      spot_price                  = "0.2"
      volume_size                 = 50
      iam_instance_profile        = aws_iam_instance_profile.runner.name
      spot_fleet_tagging_role_arn = aws_iam_role.spot_fleet_tagging.arn
      user_data                   = <<-SCRIPT
        #!/bin/bash -xe
        exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
      SCRIPT
      tags = {
        "tf-aws-gitlab-runner:instancelifecycle" = "spot:yes"
      }
    })
  }
}


# Allow Spot request to run and terminate EC2 instances
data "aws_iam_policy_document" "assume_spot_fleet" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["spotfleet.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "agent_spot_fleet" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:RunInstances",
      "ec2:CreateTags",
      "ec2:RequestSpotFleet",
      "ec2:ModifySpotFleetRequest",
      "ec2:CancelSpotFleetRequests",
      "ec2:DescribeSpotFleetRequests",
      "ec2:DescribeSpotFleetInstances",
      "ec2:DescribeSpotFleetRequestHistory",
    ]
    resources = ["*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.spot_fleet_tagging.arn]
  }
  statement {
    effect = "Allow"
    actions = [
      "iam:CreateServiceLinkedRole",
      "iam:ListRoles",
      "iam:ListInstanceProfiles",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_instance_profile" "runner" {
  name = module.gitlab_runner.runner_role_name
  role = module.gitlab_runner.runner_role_name
}

resource "aws_iam_role_policy" "spot_fleet" {
  role   = module.gitlab_runner.runner_agent_role_name
  name   = "SpotFleet"
  policy = data.aws_iam_policy_document.agent_spot_fleet.json
}

resource "aws_iam_role" "spot_fleet_tagging" {
  name               = "SpotFleetTaggingRoleForGitlabRunner"
  assume_role_policy = data.aws_iam_policy_document.assume_spot_fleet.json
}

resource "aws_iam_role_policy_attachment" "spot_request_policy" {
  role       = aws_iam_role.spot_fleet_tagging.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetTaggingRole"
}

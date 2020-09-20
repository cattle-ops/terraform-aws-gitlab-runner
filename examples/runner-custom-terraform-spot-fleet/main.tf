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
  # We use public subnets...
  subnet_ids = tolist(module.vpc.public_subnets)
  # ...and 4 quite powerful instances (4 cores, at least 8GBs of RAM)
  instance_types = ["c5a.xlarge", "c5.xlarge", "m5a.xlarge", "m5.xlarge"]
}

# As we create Spot Fleet Requests via Terraform inside Gitlab Runner Agent,
# we have to allow Gitlab Runner Agent instance to manage spot fleet requests
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

resource "aws_iam_role_policy" "spot_fleet" {
  role   = module.gitlab_runner.runner_agent_role_name
  name   = "SpotFleet"
  policy = data.aws_iam_policy_document.agent_spot_fleet.json
}

# We also need instance profile and Spot Fleet Tagging role for runners

data "aws_iam_policy_document" "assume_spot_fleet" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["spotfleet.amazonaws.com"]
    }
  }
}

resource "aws_iam_instance_profile" "runner" {
  name = module.gitlab_runner.runner_role_name
  role = module.gitlab_runner.runner_role_name
}

resource "aws_iam_role" "spot_fleet_tagging" {
  name               = "SpotFleetTaggingRoleForGitlabRunner"
  assume_role_policy = data.aws_iam_policy_document.assume_spot_fleet.json
}

resource "aws_iam_role_policy_attachment" "spot_request_policy" {
  role       = aws_iam_role.spot_fleet_tagging.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetTaggingRole"
}

data "aws_ami" "ubuntu" {
  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}

# Finally, we can create a runner itself - it's quite bulky,
# but remember that we're now provisioning docker-machines with Terraform,
# which is more complex than before

module "gitlab_runner" {
  source = "../../"

  # CORE OF THIS EXAMPLE

  # Yes, we can pass terraform to gitlab-runner/docker-machine and it apparently works!
  # If docker_machine_driver is not set to `amazonec2`, you have to set everything manually via
  # docker_machine_options variable
  docker_machine_driver = "terraform"

  # Terraform driver has it's own config, check out https://github.com/krzysztof-miemiec/docker-machine-driver-terraform
  # for more details
  docker_machine_options = [
    # Don't forget about trailing slash, which indicates that configuration is a folder and not a single file
    "terraform-config=/extra-files/runners-config.zip/",
    "terraform-variables-from=/extra-files/runners-vars.json",
    "engine-storage-driver=overlay2"
  ]

  # First, lets include a bunch of files:
  # - terraform configuration which is used by terraform docker-machine driver to deploy runner instance
  # - script which is used to download and install terraform and docker-machine-driver-terraform
  # - configuration file for terraform-created runners
  extra_files = {
    "runners-config/main.tf"      = file("${path.module}/worker-config/main.tf")
    "runners-config/variables.tf" = file("${path.module}/worker-config/variables.tf")
    "runners-config/outputs.tf"   = file("${path.module}/worker-config/outputs.tf")
    "docker-machine-terraform.sh" = templatefile("${path.module}/docker-machine-terraform.sh", {
      terraform_url = "https://releases.hashicorp.com/terraform/0.13.3/terraform_0.13.3_linux_amd64.zip"
      # This is a fork of @tintoy's docker-machine driver, updated to make TF >=0.12 & <0.14 run with it
      terraform_driver_url = "https://github.com/krzysztof-miemiec/docker-machine-driver-terraform/releases/download/v0.4.2/linux-amd64.zip"
    })

    # This corresponds to variables.tf in worker-config folder
    # Keep in mind that variables set below do not affect instances created using Terraform
    # and everything has to be set (again) here
    "runners-vars.json" = jsonencode({
      image_id                    = data.aws_ami.ubuntu.image_id
      instance_types              = local.instance_types
      region                      = var.aws_region
      subnets                     = local.subnet_ids
      security_group_ids          = [module.gitlab_runner.runner_sg_id]
      spot_price                  = "0.2"
      volume_size                 = 50
      iam_instance_profile        = aws_iam_instance_profile.runner.name
      spot_fleet_tagging_role_arn = aws_iam_role.spot_fleet_tagging.arn
      tags = {
        "tf-aws-gitlab-runner:instancelifecycle" = "spot:yes"
      }
    })
  }

  # Let's run Terraform & docker-machine-driver-terraform installation script on boot
  userdata_pre_install = <<SCRIPT
    chmod +x /extra-files/docker-machine-terraform.sh
    /extra-files/docker-machine-terraform.sh
    # We have to pass TF config as zip file, because docker-machine-driver-terraform symlinks a folder if passed directly
    (cd /extra-files/runners-config; zip -r ../runners-config.zip *)
  SCRIPT

  # After each new configuration change that happens on S3, don't forget to reload runners-config
  # extra_files we passed earlier, are pulled to `/extra-files` directory on Gitlab Agent instance
  # Let's zip the contents of runner config after each config update
  post_reload_config = "(cd /extra-files/runners-config; zip -r ../runners-config.zip *)"

  # BORING STUFF BELOW
  # This is mostly a standard Gitlab Runner configuration, nothing new here
  # (compared to other examples)

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
  runners_idle_time           = 3600
  runners_off_peak_idle_count = 0
  runners_off_peak_timezone   = var.timezone
  runners_off_peak_periods    = jsonencode(["* * 0-9,17-23 * * mon-fri *", "* * * * * sat,sun *"])
  runners_off_peak_idle_time  = 1800

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
}

data "aws_availability_zones" "available_main_region" {
  state = "available"
}

# VPC Flow logs are not needed here
# kics-scan ignore-line
module "vpc_main_region" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.70"

  name = "vpc-${var.environment}"
  cidr = "10.1.0.0/16"

  azs            = [data.aws_availability_zones.available_main_region.names[0]]
  public_subnets = ["10.1.101.0/24"]

  map_public_ip_on_launch = "false"

  tags = {
    Environment = var.environment
  }
}

module "runner_main_region" {
  source = "../../"

  environment = var.environment

  executor_docker_machine_use_private_address = false

  vpc_id    = module.vpc_main_region.vpc_id
  subnet_id = element(module.vpc_main_region.public_subnets, 0)

  executor_docker_machine_ec2_spot_price_bid = "on-demand-price"

  runner_manager_gitlab_runner_name             = var.runner_name
  runner_manager_gitlab_url                     = var.gitlab_url
  executor_extra_environment_variables = ["KEY=Value", "FOO=bar"]

  executor_docker_options = {
    privileged = "false"
    volumes    = ["/var/run/docker.sock:/var/run/docker.sock"]
  }

  runner_manager_gitlab_registration_config = {
    registration_token = var.registration_token
    tag_list           = "docker_spot_runner"
    description        = "runner public - auto"
    locked_to_project  = "false"
    run_untagged       = "false"
    maximum_timeout    = "3600"
  }

  security_group_prefix                   = "my-security-group"
  runner_manager_instance_prefix                   = "my-runner-agent"
  executor_docker_machine_instance_prefix = "my-runners-dm"
  iam_object_prefix                       = local.name_iam_objects_main_region

  executor_cache_shared = "true"

  executor_cache_s3_bucket_prefix                  = local.cache_bucket_prefix_main_region
  executor_cache_s3_bucket_name_include_account_id = false
}

# VPC Flow logs are not needed here
# kics-scan ignore-line
module "vpc_alternate_region" {
  providers = {
    aws = aws.alternate_region
  }

  source  = "terraform-aws-modules/vpc/aws"
  version = "2.70"

  name = "vpc-${var.environment}"
  cidr = "10.1.0.0/16"

  # Have to construct the zone names here because the data source always uses the main region
  azs            = ["${var.aws_alternate_region}a", "${var.aws_alternate_region}b", "${var.aws_alternate_region}c"]
  public_subnets = ["10.1.101.0/24"]

  map_public_ip_on_launch = "false"

  tags = {
    Environment = var.environment
  }
}

module "runner_alternate_region" {
  providers = {
    aws = aws.alternate_region
  }

  source = "../../"

  environment = var.environment

  executor_docker_machine_use_private_address = false

  vpc_id    = module.vpc_alternate_region.vpc_id
  subnet_id = element(module.vpc_alternate_region.public_subnets, 0)

  executor_docker_machine_ec2_spot_price_bid = "on-demand-price"

  runner_manager_gitlab_runner_name             = var.runner_name
  runner_manager_gitlab_url                     = var.gitlab_url
  executor_extra_environment_variables = ["KEY=Value", "FOO=bar"]

  executor_docker_options = {
    privileged = "false"
    volumes    = ["/var/run/docker.sock:/var/run/docker.sock"]
  }

  runner_manager_gitlab_registration_config = {
    registration_token = var.registration_token
    tag_list           = "docker_spot_runner"
    description        = "runner public - auto"
    locked_to_project  = "true"
    run_untagged       = "false"
    maximum_timeout    = "3600"
    access_level       = "ref_protected"
  }

  security_group_prefix                   = "my-security-group"
  runner_manager_instance_prefix                   = "my-runner-agent"
  executor_docker_machine_instance_prefix = "my-runners-dm"
  iam_object_prefix                       = local.name_iam_objects_main_region # <--

  executor_cache_shared = "true"

  executor_cache_s3_bucket_prefix                  = local.cache_bucket_prefix_alternate_region
  executor_cache_s3_bucket_name_include_account_id = false
}

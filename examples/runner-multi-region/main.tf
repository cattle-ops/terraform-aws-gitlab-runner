data "aws_availability_zones" "available_main_region" {
  state = "available"
}

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

  aws_region  = var.aws_main_region
  environment = var.environment

  runners_use_private_address = false

  vpc_id    = module.vpc_main_region.vpc_id
  subnet_id = element(module.vpc_main_region.public_subnets, 0)

  docker_machine_spot_price_bid = "on-demand-price"

  runners_name             = var.runner_name
  runners_gitlab_url       = var.gitlab_url
  runners_environment_vars = ["KEY=Value", "FOO=bar"]

  runners_privileged         = "false"
  runners_additional_volumes = ["/var/run/docker.sock:/var/run/docker.sock"]

  gitlab_runner_registration_config = {
    registration_token = var.registration_token
    tag_list           = "docker_spot_runner"
    description        = "runner public - auto"
    locked_to_project  = "false"
    run_untagged       = "false"
    maximum_timeout    = "3600"
  }

  overrides = {
    name_sg                     = "my-security-group"
    name_runner_agent_instance  = "my-runner-agent"
    name_docker_machine_runners = "my-runners-dm"
    name_iam_objects            = local.name_iam_objects_main_region
  }

  cache_shared = "true"

  cache_bucket_prefix                  = local.cache_bucket_prefix_main_region
  cache_bucket_name_include_account_id = false
}

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

  aws_region  = var.aws_alternate_region
  environment = var.environment

  runners_use_private_address = false

  vpc_id    = module.vpc_alternate_region.vpc_id
  subnet_id = element(module.vpc_alternate_region.public_subnets, 0)

  docker_machine_spot_price_bid = "on-demand-price"

  runners_name             = var.runner_name
  runners_gitlab_url       = var.gitlab_url
  runners_environment_vars = ["KEY=Value", "FOO=bar"]

  runners_privileged         = "false"
  runners_additional_volumes = ["/var/run/docker.sock:/var/run/docker.sock"]

  gitlab_runner_registration_config = {
    registration_token = var.registration_token
    tag_list           = "docker_spot_runner"
    description        = "runner public - auto"
    locked_to_project  = "true"
    run_untagged       = "false"
    maximum_timeout    = "3600"
    access_level       = "ref_protected"
  }

  overrides = {
    name_sg                     = "my-security-group"
    name_runner_agent_instance  = "my-runner-agent"
    name_docker_machine_runners = "my-runners-dm"
    name_iam_objects            = local.name_iam_objects_alternate_region
  }

  cache_shared = "true"

  cache_bucket_prefix                  = local.cache_bucket_prefix_alternate_region
  cache_bucket_name_include_account_id = false
}

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

  ###############################################
  # General
  ###############################################
  environment = var.environment

  ###############################################
  # Certificates
  ###############################################

  # Public cert of my company's gitlab instance
  # Other public certs relating to my company.
  runner_gitlab = {
    url            = var.gitlab_url
    certificate    = file("${path.module}/my_gitlab_instance_cert.crt")
    ca_certificate = file("${path.module}/my_company_ca_cert_bundle.crt")
  }

  # Mount EC2 host certs in docker so all user docker images can reference them.
  # Each user image will need to do:
  # cp /etc/gitlab-runner/certs/* /usr/local/share/ca-certificates/
  # update-ca-certificates
  # Or similar OS-dependent commands. The above are an example for Ubuntu.
  runner_worker_docker_options = {
    volumes = [
      "/cache",
      "/etc/gitlab-runner/certs/:/etc/gitlab-runner/certs:ro"
    ]
  }

  ###############################################
  # Registration
  ###############################################
  runner_gitlab_registration_config = {
    registration_token = var.registration_token
    tag_list           = "docker_runner"
    description        = "runner docker - auto"
    locked_to_project  = "true"
    run_untagged       = "false"
    maximum_timeout    = "3600"
  }

  ###############################################
  # Network
  ###############################################
  vpc_id    = module.vpc.vpc_id
  subnet_id = element(module.vpc.private_subnets, 0)
  runner_instance = {
    name = var.runner_name
  }

  runner_worker = {
    type = "docker"
  }
}

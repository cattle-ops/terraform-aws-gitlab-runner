data "aws_availability_zones" "available" {
  state = "available"
}

# VPC Flow logs are not needed here
# kics-scan ignore-line
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.70"

  name = "vpc-${var.environment}"
  cidr = "10.1.0.0/16"

  azs                     = [data.aws_availability_zones.available.names[0]]
  public_subnets          = ["10.1.101.0/24"]
  enable_s3_endpoint      = true
  map_public_ip_on_launch = false

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

  # Public cert of my companys gitlab instance
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
  subnet_id = element(module.vpc.public_subnets, 0)
  runner_instance = {
    name = var.runner_name
  }

  runner_worker = {
    type = "docker"
  }
}

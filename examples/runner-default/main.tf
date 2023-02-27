data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = module.vpc.vpc_id
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"

  name = "vpc-${var.environment}"
  cidr = "10.0.0.0/16"

  azs             = [data.aws_availability_zones.available.names[0]]
  private_subnets = ["10.0.1.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Environment = var.environment
  }
}

module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "3.19.0"

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

  aws_region  = var.aws_region
  environment = var.environment

  vpc_id              = module.vpc.vpc_id
  subnet_id           = element(module.vpc.private_subnets, 0)
  metrics_autoscaling = ["GroupDesiredCapacity", "GroupInServiceCapacity"]

  runners_name             = var.runner_name
  runners_gitlab_url       = var.gitlab_url
  enable_runner_ssm_access = true

  gitlab_runner_security_group_ids = [data.aws_security_group.default.id]

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

  # Uncomment the HCL code below to configure a docker service so that registry mirror is used in auto-devops jobs
  # See https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27171 and https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#the-service-in-the-gitlab-runner-configuration-file
  # You can check this works with a CI job like:
  # <pre>
  # default:
  #    tags:
  #        - "docker_spot_runner"
  # docker-mirror-check:
  #    image: docker:20.10.16
  #    stage: build
  #    variables: 
  #        DOCKER_TLS_CERTDIR: ''
  #    script:
  #        - |
  #        - docker info
  #          if ! docker info | grep -i mirror
  #            then
  #              exit 1
  #              echo "No mirror config found"
  #          fi
  # </pre>
  #
  # If not using an official docker image for your job, you may need to specify `DOCKER_HOST: tcp://docker:2375`
  ## UNCOMMENT 6 LINES BELOW
  # runners_docker_services = [{
  #   name       = "docker:20.10.16-dind"
  #   alias      = "docker"
  #   command    = ["--registry-mirror", "https://mirror.gcr.io"]
  #   entrypoint = ["dockerd-entrypoint.sh"]
  # }]


  # Example how to configure runners, to utilize EC2 user-data feature
  # example template, creates (configurable) swap file for the runner
  # runners_userdata = templatefile("${path.module}/../../templates/swap.tpl", {
  #   swap_size = "512"
  # })
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

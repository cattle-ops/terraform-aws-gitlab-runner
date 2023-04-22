module "runner" {
  source = "../../"

  environment = var.environment

  vpc_id                             = module.vpc.vpc_id
  subnet_id                          = element(module.vpc.private_subnets, 0)




  runner_gitlab_registration_config = {
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

  runner_worker_docker_volumes_tmpfs = [
    {
      volume  = "/var/opt/cache",
      options = "rw,noexec"
    }
  ]

  runner_worker_docker_services_volumes_tmpfs = [
    {
      volume  = "/var/lib/mysql",
      options = "rw,noexec"
    }
  ]

  # working 9 to 5 :)
  runner_worker_docker_machine_autoscaling_options = [
    {
      periods    = ["* * 0-9,17-23 * * mon-fri *", "* * * * * sat,sun *"]
      idle_count = 0
      idle_time  = 60
      timezone   = var.timezone
    }
  ]

  runner_worker_docker_options = {
    privileged = "true"
    volumes    = ["/cache", "/certs/client"]
  }




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
  # runner_worker_docker_services = [{
  #   name       = "docker:20.10.16-dind"
  #   alias      = "docker"
  #   command    = ["--registry-mirror", "https://mirror.gcr.io"]
  #   entrypoint = ["dockerd-entrypoint.sh"]
  # }]


  # Example how to configure runners, to utilize EC2 user-data feature
  # example template, creates (configurable) swap file for the runner
  #   swap_size = "512"
  # })
  runner_instance = {
      collect_autoscaling_metrics = ["GroupDesiredCapacity", "GroupInServiceCapacity"]
  name = var.runner_name
  ssm_access  = true
  }
  runner_gitlab = {
      url         = var.gitlab_url
  }
  runner_worker_docker_machine_instance = {
      # start_script = templatefile("${path.module}/../../templates/swap.tpl", {
  }
  runner_worker_docker_machine_instance_spot = {
      max_price = "on-demand-price"
  }
  runner_networking = {
      allow_incoming_ping_security_group_ids = [data.aws_security_group.default.id]
  }
  runner_worker_gitlab_pipeline = {
      pre_build_script = <<EOT
        '''
        echo 'multiline 1'
        echo 'multiline 2'
        '''
        EOT
  post_build_script = "\"echo 'single line'\""
  }

}

module "runner" {
  source = "../../../"

  environment = "default"

  vpc_id    = module.vpc.vpc_id
  subnet_id = element(module.vpc.private_subnets, 0)

  runner_instance = {
    collect_autoscaling_metrics = ["GroupDesiredCapacity", "GroupInServiceCapacity"]
    name                        = "runner-name"
    ssm_access                  = true
  }

  runner_networking = {
    security_group_ids = [data.aws_security_group.default.id]
  }

  runner_gitlab = {
    url = "https://my.fancy.url/not/used"
  }

  runner_gitlab_registration_config = {
    registration_token = "some-token"
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
}

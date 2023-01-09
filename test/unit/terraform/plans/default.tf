module "runner" {
  source = "../../../"

  aws_region  = data.aws_region.this.id
  environment = "default"

  vpc_id              = module.vpc.vpc_id
  subnet_id           = element(module.vpc.private_subnets, 0)
  metrics_autoscaling = ["GroupDesiredCapacity", "GroupInServiceCapacity"]

  runners_name             = "runner-name"
  runners_gitlab_url       = "https://my.fancy.url/not/used"
  enable_runner_ssm_access = true

  gitlab_runner_security_group_ids = [data.aws_security_group.default.id]

  docker_machine_spot_price_bid = "on-demand-price"

  gitlab_runner_registration_config = {
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
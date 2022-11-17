# Example - Spot Runner - Default

In this scenario the runner agent is running on a single EC2 node and runners are created by [docker machine](https://docs.gitlab.com/runner/configuration/autoscale.html) using spot instances. Runners will scale automatically based on configuration. The module creates by default a S3 cache that is shared cross runners (spot instances).

This examples shows:

  - Usages of public / private VPC
  - You can log into the instance via SSM (Session Manager).
  - Registration via GitLab token.
  - Auto scaling using `docker+machine` executor.
  - Addtional security groups that are allowed access to the runner agent

![runners-default](https://github.com/npalm/assets/raw/main/images/terraform-aws-gitlab-runner/runner-default.png)

## Prerequisite

The Terraform version is managed using [tfenv](https://github.com/Zordrak/tfenv). If you are not using `tfenv` please check `.terraform-version` for the tested version.

<!-- BEGIN_TF_DOCS -->
----
## Example

```hcl
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = module.vpc.vpc_id
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.70"

  name = "vpc-${var.environment}"
  cidr = "10.0.0.0/16"

  azs             = [data.aws_availability_zones.available.names[0]]
  private_subnets = ["10.0.1.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_s3_endpoint = true

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
```
----

## Documentation

----
### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region. | `string` | `"eu-west-1"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | A name that identifies the environment, will used as prefix and for tagging. | `string` | `"runners-default"` | no |
| <a name="input_gitlab_url"></a> [gitlab\_url](#input\_gitlab\_url) | URL of the gitlab instance to connect to. | `string` | `"https://gitlab.com"` | no |
| <a name="input_registration_token"></a> [registration\_token](#input\_registration\_token) | Gitlab runner registration token | `string` | `"something"` | no |
| <a name="input_runner_name"></a> [runner\_name](#input\_runner\_name) | Name of the runner, will be used in the runner config.toml | `string` | `"default-auto"` | no |
| <a name="input_timezone"></a> [timezone](#input\_timezone) | Name of the timezone that the runner will be used in. | `string` | `"Europe/Amsterdam"` | no |

----
### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_runner"></a> [runner](#module\_runner) | ../../ | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 2.70 |

----
### Outputs

No outputs.

----
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.7 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | ~> 3 |

----
### Resources

| Name | Type |
|------|------|
| [null_resource.cancel_spot_requests](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_security_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_group) | data source |

----
<!-- END_TF_DOCS -->

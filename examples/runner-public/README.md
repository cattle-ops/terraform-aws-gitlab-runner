# Example - Spot Runner - Public subnets

In this scenario the multiple runner agents can be created with different configuration by instantiating the module multiple times. Runners will scale automatically based on configuration. The S3 cache can be shared cross runners by managing the cache outside the module.

![runners-cache](https://github.com/npalm/assets/raw/main/images/terraform-aws-gitlab-runner/runner-cache.png)

This examples shows:

  - Usages of public subnets.
  - Usages of multiple runner instances sharing a common cache.
  - Overrides for tag naming.
  - Registration via GitLab token.
  - Auto scaling using `docker+machine` executor.
  - Register runner as [protected](https://docs.gitlab.com/ee/ci/runners/configure_runners.html#prevent-runners-from-revealing-sensitive-information).

## Prerequisite

The Terraform version is managed using [tfenv](https://github.com/Zordrak/tfenv). If you are not using `tfenv` please check `.terraform-version` for the tested version.

<!-- BEGIN_TF_DOCS -->
----
## Example

```hcl
data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.70"

  name = "vpc-${var.environment}"
  cidr = "10.1.0.0/16"

  azs            = [data.aws_availability_zones.available.names[0]]
  public_subnets = ["10.1.101.0/24"]

  map_public_ip_on_launch = "false"

  tags = {
    Environment = var.environment
  }
}

module "cache" {
  source      = "../../modules/cache"
  environment = var.environment
}

module "runner" {
  source = "../../"

  aws_region  = var.aws_region
  environment = var.environment

  runners_use_private_address = false

  vpc_id    = module.vpc.vpc_id
  subnet_id = element(module.vpc.public_subnets, 0)

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
  }

  cache_shared = "true"

  cache_bucket = {
    create = false
    policy = module.cache.policy_arn
    bucket = module.cache.bucket
  }
}

module "runner2" {
  source = "../../"

  aws_region  = var.aws_region
  environment = "${var.environment}-2"

  runners_use_private_address = false

  vpc_id                   = module.vpc.vpc_id
  subnet_ids_gitlab_runner = module.vpc.public_subnets
  subnet_id_runners        = element(module.vpc.public_subnets, 0)

  docker_machine_spot_price_bid = "on-demand-price"

  runners_name       = var.runner_name
  runners_gitlab_url = var.gitlab_url

  gitlab_runner_registration_config = {
    registration_token = var.registration_token
    tag_list           = "docker_spot_runner_2"
    description        = "runner public - auto"
    locked_to_project  = "true"
    run_untagged       = "false"
    maximum_timeout    = "3600"
  }

  cache_shared = "true"

  cache_bucket = {
    create = false
    policy = module.cache.policy_arn
    bucket = module.cache.bucket
  }
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
| <a name="input_environment"></a> [environment](#input\_environment) | A name that identifies the environment, will used as prefix and for tagging. | `string` | `"runner-public"` | no |
| <a name="input_gitlab_url"></a> [gitlab\_url](#input\_gitlab\_url) | URL of the gitlab instance to connect to. | `string` | `"https://gitlab.com"` | no |
| <a name="input_registration_token"></a> [registration\_token](#input\_registration\_token) | Gitlab runner registration token | `string` | `"something"` | no |
| <a name="input_runner_name"></a> [runner\_name](#input\_runner\_name) | Name of the runner, will be used in the runner config.toml | `string` | `"public-auto"` | no |

----
### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cache"></a> [cache](#module\_cache) | ../../modules/cache | n/a |
| <a name="module_runner"></a> [runner](#module\_runner) | ../../ | n/a |
| <a name="module_runner2"></a> [runner2](#module\_runner2) | ../../ | n/a |
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

----
<!-- END_TF_DOCS -->

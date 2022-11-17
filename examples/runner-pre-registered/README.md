# Example - Spot Runner - Private subnets

This is the previous default example. For this example you need to register the runner before running terraform and provide the runner token. Since version 3+ the runner can register itself by providing the registration token. This example is provided to showcase backwards compatibility.

## Prerequisite

The terraform version is managed using [tfenv](https://github.com/Zordrak/tfenv). If you are not using `tfenv` please check `.terraform-version` for the tested version.

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

  vpc_id    = module.vpc.vpc_id
  subnet_id = element(module.vpc.private_subnets, 0)

  runners_name       = var.runner_name
  runners_gitlab_url = var.gitlab_url
  runners_token      = var.runner_token

  # working 9 to 5 :)
  runners_machine_autoscaling = [
    {
      periods    = ["\"* * 0-9,17-23 * * mon-fri *\"", "\"* * * * * sat,sun *\""]
      idle_count = 0
      idle_time  = 60
      timezone   = var.timezone
    }
  ]
}
```
----

## Documentation

----
### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region. | `string` | `"eu-west-1"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | A name that identifies the environment, will used as prefix and for tagging. | `string` | `"ci-runners"` | no |
| <a name="input_gitlab_url"></a> [gitlab\_url](#input\_gitlab\_url) | URL of the gitlab instance to connect to. | `string` | n/a | yes |
| <a name="input_runner_name"></a> [runner\_name](#input\_runner\_name) | Name of the runner, will be used in the runner config.toml | `string` | n/a | yes |
| <a name="input_runner_token"></a> [runner\_token](#input\_runner\_token) | Token for the runner, will be used in the runner config.toml | `string` | n/a | yes |
| <a name="input_timezone"></a> [timezone](#input\_timezone) | Timezone that will be set for the runner. | `string` | `"Europe/Amsterdam"` | no |

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
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |

----
<!-- END_TF_DOCS -->

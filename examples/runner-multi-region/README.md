# Example - Spot Runner - Multi-region

In this scenario, we create multiple runner agents similarly to the _runner-public_ example but in different regions. Runners can be created with different configuration by instantiating the module multiple times. Runners will scale automatically based on configuration. The S3 cache can be shared cross runners by managing the cache outside the module.

![runners-cache](https://github.com/npalm/assets/raw/master/images/terraform-aws-gitlab-runner/runner-cache.png)

This examples shows:

  - Multi-region deployment.
  - Usages of public subnets.
  - Usages of multiple runner instances sharing a common cache.
  - Overrides for tag naming.
  - Registration via GitLab token.
  - Auto scaling using `docker+machine` executor.

Note that global AWS resources like IAM policies and S3 buckets must be unique across regions.
To duplicate the Gitlab runner deployment to multiple regions, we therefore have to use the name overrides for the IAM resources (_overrides.name_iam_objects_) respectively for the S3 cache bucket (_cache_bucket_prefix_) in the modules _runner_main_region_ and _runner_alternate_region_.

```hcl
# examples/runner-multi-region/main.tf
# ...

module "runner_main_region" {
  # ...
  
  overrides = {
    name_sg                     = "my-security-group"
    name_runner_agent_instance  = "my-runner-agent"
    name_docker_machine_runners = "my-runners-dm"
    name_iam_objects            = local.name_iam_objects_main_region # <--
  }

  # ...

  cache_bucket_prefix                  = local.cache_bucket_prefix_main_region # <--
  cache_bucket_name_include_account_id = false
}

# ...

module "runner_alternate_region" {
  # ...
  
  overrides = {
    name_sg                     = "my-security-group"
    name_runner_agent_instance  = "my-runner-agent"
    name_docker_machine_runners = "my-runners-dm"
    name_iam_objects            = local.name_iam_objects_alternate_region # <--
  }

  # ...

  cache_bucket_prefix                  = local.cache_bucket_prefix_alternate_region # <--
  cache_bucket_name_include_account_id = false
}
```

## Prerequisite

The Terraform version is managed using [tfenv](https://github.com/Zordrak/tfenv). If you are not using `tfenv` please check `.terraform-version` for the tested version.

## Providers

| Name | Version |
|------|---------|
| aws | 2.56 |
| local | 1.4 |
| null | 2.1.2 |
| tls | 2.1.1 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| aws\_main\_region | Main AWS region to deploy to. | `string` | `"eu-west-1"` | no |
| aws\_alternate\_region | Main AWS region to deploy to. | `string` | `"eu-central-1"` | no |
| environment | A name that identifies the environment, will used as prefix and for tagging. | `string` | `"runner-public"` | no |
| gitlab\_url | URL of the gitlab instance to connect to. | `string` | `"https://gitlab.com"` | no |
| registration\_token | n/a | `any` | n/a | yes |
| runner\_name | Name of the runner, will be used in the runner config.toml | `string` | `"public-auto"` | no |

## Outputs

No output.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 4.49.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | 2.2.3 |
| <a name="requirement_null"></a> [null](#requirement\_null) | 3.2.1 |
| <a name="requirement_random"></a> [random](#requirement\_random) | 3.4.3 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | 4.0.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.49.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_runner_alternate_region"></a> [runner\_alternate\_region](#module\_runner\_alternate\_region) | ../../ | n/a |
| <a name="module_runner_main_region"></a> [runner\_main\_region](#module\_runner\_main\_region) | ../../ | n/a |
| <a name="module_vpc_alternate_region"></a> [vpc\_alternate\_region](#module\_vpc\_alternate\_region) | terraform-aws-modules/vpc/aws | 2.70 |
| <a name="module_vpc_main_region"></a> [vpc\_main\_region](#module\_vpc\_main\_region) | terraform-aws-modules/vpc/aws | 2.70 |

## Resources

| Name | Type |
|------|------|
| [aws_availability_zones.available_main_region](https://registry.terraform.io/providers/hashicorp/aws/4.49.0/docs/data-sources/availability_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_alternate_region"></a> [aws\_alternate\_region](#input\_aws\_alternate\_region) | Alternate AWS region to deploy to. | `string` | `"eu-central-1"` | no |
| <a name="input_aws_main_region"></a> [aws\_main\_region](#input\_aws\_main\_region) | Main AWS region to deploy to. | `string` | `"eu-west-1"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | A name that identifies the environment, will used as prefix and for tagging. | `string` | `"runner-public"` | no |
| <a name="input_gitlab_url"></a> [gitlab\_url](#input\_gitlab\_url) | URL of the gitlab instance to connect to. | `string` | `"https://gitlab.com"` | no |
| <a name="input_registration_token"></a> [registration\_token](#input\_registration\_token) | n/a | `any` | n/a | yes |
| <a name="input_runner_name"></a> [runner\_name](#input\_runner\_name) | Name of the runner, will be used in the runner config.toml | `string` | `"public-auto"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->

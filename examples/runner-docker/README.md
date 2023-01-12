# Example - Spot Runner - Private subnet

In this scenario the runner agent is running on a single EC2 node and runners are created by [docker machine](https://docs.gitlab.com/runner/configuration/autoscale.html) using spot instances. Runners will scale automatically based on configuration. The module creates by default a S3 cache that is shared cross runners (spot instances).

![runners-default](https://github.com/npalm/assets/raw/main/images/terraform-aws-gitlab-runner/runner-default.png)

This examples shows:

  - Usages of public / private subnets.
  - Usages of runner of peak time mode configuration.
  - Registration via GitLab token.
  - Auto scaling using `docker+machine` executor. ➜ tmp cat terraform-aws-gitlab-runner/examples/runner-docker/\_docs/README.md

# Example - Runner - Docker runner

In this scenario the docker executor is used to schedule the builds. Builds will run on the same EC2 instance as the agent. No auto scaling is supported.

![runners-docker](https://github.com/npalm/assets/raw/main/images/terraform-aws-gitlab-runner/runner-docker.png)

## Prerequisite

The terraform version is managed using [tfenv](https://github.com/Zordrak/tfenv). If you are not using `tfenv` please check `.terraform-version` for the tested version.

## Providers

| Name | Version |
| ---- | ------- |
| aws  | 2.56    |

## Inputs

| Name                | Description                                                                  | Type     | Default                | Required |
| ------------------- | ---------------------------------------------------------------------------- | -------- | ---------------------- | :------: |
| aws\_region         | AWS region.                                                                  | `string` | `"eu-west-1"`          |    no    |
| environment         | A name that identifies the environment, will used as prefix and for tagging. | `string` | `"runners-docker"`     |    no    |
| gitlab\_url         | URL of the gitlab instance to connect to.                                    | `string` | `"https://gitlab.com"` |    no    |
| registration\_token | n/a                                                                          | `any`    | n/a                    |   yes    |
| runner\_name        | Name of the runner, will be used in the runner config.toml                   | `string` | `"docker"`             |    no    |

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
| <a name="module_runner"></a> [runner](#module\_runner) | ../../ | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 3.18.1 |
| <a name="module_vpc_endpoints"></a> [vpc\_endpoints](#module\_vpc\_endpoints) | terraform-aws-modules/vpc/aws//modules/vpc-endpoints | 3.18.1 |

## Resources

| Name | Type |
|------|------|
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/4.49.0/docs/data-sources/availability_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region. | `string` | `"eu-west-1"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | A name that identifies the environment, will used as prefix and for tagging. | `string` | `"runners-docker"` | no |
| <a name="input_gitlab_url"></a> [gitlab\_url](#input\_gitlab\_url) | URL of the gitlab instance to connect to. | `string` | `"https://gitlab.com"` | no |
| <a name="input_registration_token"></a> [registration\_token](#input\_registration\_token) | n/a | `any` | n/a | yes |
| <a name="input_runner_name"></a> [runner\_name](#input\_runner\_name) | Name of the runner, will be used in the runner config.toml | `string` | `"docker"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
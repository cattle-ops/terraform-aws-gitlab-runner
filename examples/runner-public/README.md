# Example - Spot Runner - Public subnets

In this scenario the multiple runner agents can be created with different configuration by instantiating the module multiple times. Runners will scale automatically based on configuration. The S3 cache can be shared cross runners by managing the cache outside the module.

![runners-cache](https://github.com/npalm/assets/raw/master/images/terraform-aws-gitlab-runner/runner-cache.png)

This examples shows:

  - Usages of public subnets.
  - Usages of multiple runner instances sharing a common cache.
  - Overrides for tag naming.
  - Registration via GitLab token.
  - Auto scaling using `docker+machine` executor.
  - Register runner as [protected](https://docs.gitlab.com/ee/ci/runners/#protected-runners).

## Prerequisite

The Terraform version is managed using [tfenv](https://github.com/Zordrak/tfenv). If you are not using `tfenv` please check `.terraform-version` for the tested version.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| aws\_region | AWS region. | string | `"eu-west-1"` | no |
| environment | A name that identifies the environment, will used as prefix and for tagging. | string | `"runner-public"` | no |
| gitlab\_url | URL of the gitlab instance to connect to. | string | `"https://gitlab.com"` | no |
| private\_ssh\_key\_filename |  | string | `"generated/id_rsa"` | no |
| public\_ssh\_key\_filename |  | string | `"generated/id_rsa.pub"` | no |
| registration\_token |  | string | n/a | yes |
| runner\_name | Name of the runner, will be used in the runner config.toml | string | `"public-auto"` | no |

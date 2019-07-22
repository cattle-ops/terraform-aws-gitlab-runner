# Example - Spot Runner - Public subnets

In this scenario the multiple runner agents can be created with different configuration by instantiating the module multiple times. Runners will scale automatically based on configuration. The S3 cache can be shared cross runners by managing the cache outside the module.

![runners-cache](https://github.com/npalm/assets/raw/master/images/terraform-aws-gitlab-runner/runner-cache.png)

This examples shows:

  - Usages of public subnets.
  - Useages of multiple runner instances sharing a common cache.
  - Overrides for tag naming.
  - Registration via GitLab token.
  - Auto scaling using `docker+machine` executor.

## Prerequisite

The Terraform version is managed using [tfenv](https://github.com/Zordrak/tfenv). If you are not using `tfenv` please check `.terraform-version` for the tested version.

➜ tmp cat terraform-aws-gitlab-runner/examples/runner-default/\_docs/README.md

# Example - Spot Runner - Private subnet

In this scenario the runner agent is running on a single EC2 node and runners are created by [docker machine](https://docs.gitlab.com/runner/configuration/autoscale.html) using spot instances. Runners will scale automatically based on configuration. The module creates by default a S3 cache that is shared cross runners (spot instances).

![runners-default](https://github.com/npalm/assets/raw/master/images/terraform-aws-gitlab-runner/runner-default.png)

This examples shows:

  - Usages of public / private subnets.
  - Usages of runner of peak time mode configuration.
  - Registration via GitLab token.
  - Auto scaling using `docker+machine` executor.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| aws\_region | AWS region. | string | `"eu-west-1"` | no |
| environment | A name that identifies the environment, will used as prefix and for tagging. | string | `"runners-default"` | no |
| gitlab\_url | URL of the gitlab instance to connect to. | string | `"https://gitlab.com"` | no |
| private\_ssh\_key\_filename |  | string | `"generated/id_rsa"` | no |
| public\_ssh\_key\_filename |  | string | `"generated/id_rsa.pub"` | no |
| registration\_token |  | string | n/a | yes |
| runner\_name | Name of the runner, will be used in the runner config.toml | string | `"default-auto"` | no |
| timezone | Name of the timezone that the runner will be used in. | string | `"Europe/Amsterdam"` | no |

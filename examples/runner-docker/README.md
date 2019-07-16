# Example - Runner - Docker runner

In this scenario the docker executor is used to schedule the builds. Builds will run on the same EC2 instance as the agent. No auto scaling is supported.

![runners-docker](https://github.com/npalm/assets/raw/master/images/terraform-aws-gitlab-runner/runner-docker.png)

## Prerequisite

The terraform version is managed using [tfenv](https://github.com/Zordrak/tfenv). If you are not using `tfenv` please check `.terraform-version` for the tested version.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| aws\_region | AWS region. | string | `"eu-west-1"` | no |
| environment | A name that identifies the environment, will used as prefix and for tagging. | string | `"runners-docker"` | no |
| gitlab\_url | URL of the gitlab instance to connect to. | string | `"https://www.gitlab.com"` | no |
| private\_ssh\_key\_filename |  | string | `"generated/id_rsa"` | no |
| public\_ssh\_key\_filename |  | string | `"generated/id_rsa.pub"` | no |
| registration\_token |  | string | n/a | yes |
| runner\_name | Name of the runner, will be used in the runner config.toml | string | `"docker"` | no |

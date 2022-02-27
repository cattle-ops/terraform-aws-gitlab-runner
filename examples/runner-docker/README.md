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

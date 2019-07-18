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
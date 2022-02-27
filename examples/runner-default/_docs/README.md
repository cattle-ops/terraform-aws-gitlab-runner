# Example - Spot Runner - Default

In this scenario the runner agent is running on a single EC2 node and runners are created by [docker machine](https://docs.gitlab.com/runner/configuration/autoscale.html) using spot instances. Runners will scale automatically based on configuration. The module creates by default a S3 cache that is shared cross runners (spot instances).

This examples shows:
- Usages of public / private VPC
- No SSH keys, you can log into the instance via SSM (Session Manager).
- Registration via GitLab token.
- Auto scaling using `docker+machine` executor.
- Addtional security groups that are allowed access to the runner agent
- A multiline pre build script
- A single line post build script

![runners-default](https://github.com/npalm/assets/raw/main/images/terraform-aws-gitlab-runner/runner-default.png)


## Prerequisite

The Terraform version is managed using [tfenv](https://github.com/Zordrak/tfenv). If you are not using `tfenv` please check `.terraform-version` for the tested version.

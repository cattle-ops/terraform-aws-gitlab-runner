# Example - Spot Runner - Private

In this scenario the runner agent is running on a single EC2 node and runners are created by [docker machine](https://docs.gitlab.com/runner/configuration/autoscale.html) using spot instances in a private subnet.
Runners will scale automatically based on configuration.

The gitlab runner agent is in a private subnet and is accessible from the default security group as an example of how to access this server.
The default security group can be replaced with a security group with a bastion host in it or another service or instance.

The module creates by default a S3 cache that is shared cross runners (spot instances).

This examples shows:
- Usages of private VPC
- Use of a SSH key
- Registration via GitLab token.
- Auto scaling using `docker+machine` executor.

![runners-default](https://github.com/npalm/assets/raw/master/images/terraform-aws-gitlab-runner/runner-default.png)


## Prerequisite

The Terraform version is managed using [tfenv](https://github.com/Zordrak/tfenv). If you are not using `tfenv` please check `.terraform-version` for the tested version.

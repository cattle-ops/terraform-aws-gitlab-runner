# Example - Runner - Docker runner

In this scenario the docker executor is used to schedule the builds. Builds will run on the same EC2 instance as the agent. No auto scaling is supported.

![runners-docker](https://github.com/npalm/assets/raw/master/images/terraform-aws-gitlab-runner/runner-docker.png)


## Prerequisite

The terraform version is managed using [tfenv](https://github.com/Zordrak/tfenv). If you are not using `tfenv` please check `.terraform-version` for the tested version.

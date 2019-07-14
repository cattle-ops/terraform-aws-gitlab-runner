# Example - Spot Runner - Private subnet

In this scenario the runner agent is running on a single EC2 node and runners are created by [docker machine](https://docs.gitlab.com/runner/configuration/autoscale.html) using spot instances. Runners will scale automatically based on configuration. The module creates by default a S3 cache that is shared cross runners (spot instances). 

![runners-default](https://github.com/npalm/assets/raw/master/images/terraform-aws-gitlab-runner/runner-default.png)

This examples shows:
- Usages of public / private subnets.
- Usages of runner of peak time mode configuration.
- Registration via GitLab token.
- Auto scaling using `docker+machine` executor.

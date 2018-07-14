[![Build Status](https://travis-ci.com/npalm/terraform-aws-gitlab-runner.svg?branch=master)](https://travis-ci.com/npalm/terraform-aws-gitlab-runner)
# Terraform module for GitLab auto scaling runners on Spot instances

This repo contains a terraform module and example to run a [GitLab CI multi runner](https://docs.gitlab.com/runner/) on AWS Spot instances. See the blog post at [040code](https://040code.github.io/2017/12/09/runners-on-the-spot/) for a detailed descritpion of the setup.

![GitLab Runners](https://github.com/npalm/assets/raw/master/images/2017-12-06_gitlab-multi-runner-aws.png)

The setup is based on the blog post: [Auto scale GitLab CI runners and save 90% on EC2 costs] (https://about.gitlab.com/2017/11/23/autoscale-ci-runners/) The created runner will have by default a shared cache in S3 and logging is streamed to CloudWatch. The cache in S3 will expire in X days, see configuration. The logging can be disabled.

## Prerequisites

### Terraform
Ensure you have Terraform installed, see `.terraform-version` for the used version. A handy tool to mange your terraform version is [tfenv](https://github.com/kamatama41/tfenv).

On mac simple install tfenv using brew.
```
brew install tfenv
```
Next install a terraform version.
```
tfenv install <version>
```

### AWS
To run the terraform scripts you need to have AWS keys.
Example file:
```
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
```


### Configuration GitLab runner token
Currently register a new runner is a manual process. See the GitLab Runner [documentation](https://docs.gitlab.com/runner/register/index.html#docker) for more details.
```
docker run -it --rm gitlab/gitlab-runner register
```
Provide the details in the interactive terminal. Once done the token can be found in the GitLab runners section, choose edit to get the token or see the config.toml file.


## Usage

### Configuration
Update the variables in `terraform.tfvars` to your needs and add the following variables, see previous step for how to obtain the token.
```
runner_name  = "NAME_OF_YOUR_RUNNER"
gitlab_url   = "GIT_LAB_URL"
runner_token  = "RUNNER_TOKEN"
```


### Usage module.
```

module "gitlab-runner" {
  source  = "npalm/gitlab-runner/aws"

  source = "npalm/gitlab-runner/aws"
  version = "1.0.0"

  aws_region              = "${var.aws_region}"
  environment             = "${var.environment}"
  ssh_public_key          = "${file("${var.ssh_key_file}")}"

  vpc_id                  = "${module.vpc.vpc_id}"
  subnet_id_gitlab_runner = "${element(module.vpc.private_subnets, 0)}"
  subnet_id_runners       = "${element(module.vpc.private_subnets, 0)}"

  runners_name            = "${var.runner_name}"
  runners_gitlab_url      = "${var.gitlab_url}"
  runners_token           = "${var.runner_token}"
}
```

All variables and defaults:

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| amazon_optimized_amis | AMI map per region-zone for the gitlab-runner instance AMI. | map | `<map>` | no |
| aws_region | AWS region. | string | - | yes |
| cache_expiration_days | Number of days before cache objects expires. | string | `1` | no |
| cache_user | User name of the user to create to write and read to the s3 cache. | string | `cache_user` | no |
| docker_machine_instance_type | Instance type used for the instances hosting docker-machine. | string | `m4.large` | no |
| docker_machine_spot_price_bid | Spot price bid. | string | `0.04` | no |
| docker_machine_user | User name for the user to create spot instances to host docker-machine. | string | `docker-machine` | no |
| docker_machine_version | Version of docker-machine. | string | `0.15.0` | no |
| enable_cloudwatch_logging | Enable or disable the CloudWatch logging. | string | `1` | no |
| environment | A name that identifies the environment, will used as prefix and for tagging. | string | - | yes |
| gitlab_runner_version | Version for the gitlab runner. | string | `11.0.0` | no |
| instance_type | Instance type used for the gitlab-runner. | string | `t2.micro` | no |
| runners_concurrent | Concurrent value for the runners, will be used in the runner config.toml | string | `10` | no |
| runners_gitlab_url | URL of the gitlab instance to connect to. | string | - | yes |
| runners_idle_count | Idle count of the runners, will be used in the runner config.toml | string | `0` | no |
| runners_idle_time | Idle time of the runners, will be used in the runner config.toml | string | `600` | no |
| runners_limit | Limit for the runners, will be used in the runner config.toml | string | `0` | no |
| runners_monitoring | Enable detailed cloudwatch monitoring for spot instances. | string | `false` | no |
| runners_name | Name of the runner, will be used in the runner config.toml | string | - | yes |
| runners_off_peak_idle_count | Off peak idle count of the runners, will be used in the runner config.toml. | string | `0` | no |
| runners_off_peak_idle_time | Off peak idle time of the runners, will be used in the runner config.toml. | string | `0` | no |
| runners_off_peak_periods | Off peak periods of the runners, will be used in the runner config.toml. | string | `` | no |
| runners_off_peak_timezone | Off peak idle time zone of the runners, will be used in the runner config.toml. | string | `` | no |
| runners_privilled | Runners will run in privilled mode, will be used in the runner config.toml | string | `true` | no |
| runners_root_size | Runnner instance root size in GB. | string | `16` | no |
| runners_token | Token for the runner, will be used in the runner config.toml | string | - | yes |
| ssh_public_key | Public SSH key used for the gitlab-runner ec2 instance. | string | - | yes |
| subnet_id_gitlab_runner | Subnet used for hosting the gitlab-runner. | string | - | yes |
| subnet_id_runners | Subnet used to hosts the docker-machine runners. | string | - | yes |
| vpc_id | The VPC that is used for the instances. | string | - | yes |

## Example

An example is provided, execute the following steps to run the sample. Ensure your AWS and Terraform environment is set up correctly. All commands below are supposed to be run inside the directory `example`.

### AWS keys
Run `init.sh` to create SSH keys for the runner instance.

### Configure GitLab
Register a new runner:
```
docker run -it --rm gitlab/gitlab-runner register
```
Once done, lookup the token in GitLab and update the `terraform.tfvars` file.

## Create runner
Run `terraform init` to initialise terraform. Next you can run `terraform plan` to inspect the resources that will be created.

To create the runner run:
```
terraform apply
```
To destroy runner:
```
terraform destroy
```

## Notes:
- A user is create for the gitlab-runner / docker-machine to create ec2 instances, the permissions are NOT very restrictive.

[![Build Status](https://travis-ci.com/npalm/terraform-aws-gitlab-runner.svg?branch=master)](https://travis-ci.com/npalm/terraform-aws-gitlab-runner)
[![Gitter](https://badges.gitter.im/terraform-aws-gitlab-runner/Lobby.svg)](https://gitter.im/terraform-aws-gitlab-runner/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

# Terraform module for GitLab auto scaling runners on Spot instances

This repo contains a terraform module and example to run a [GitLab CI multi runner](https://docs.gitlab.com/runner/) on AWS Spot instances. See the blog post at [040code](https://040code.github.io/2017/12/09/runners-on-the-spot/) for a detailed description of the setup.

![GitLab Runners](https://github.com/npalm/assets/raw/master/images/2017-12-06_gitlab-multi-runner-aws.png)

The setup is based on the blog post: [Auto scale GitLab CI runners and save 90% on EC2 costs](https://about.gitlab.com/2017/11/23/autoscale-ci-runners/) The created runner will have by default a shared cache in S3 and logging is streamed to CloudWatch. The cache in S3 will expire in X days, see configuration. The logging can be disabled.

Besides the auto scaling option (docker+machine executor) the docker executor is supported as wel for a single node.

## Prerequisites

### Terraform

Ensure you have Terraform installed, see `.terraform-version` for the used version. A handy tool to mange your terraform version is [tfenv](https://github.com/kamatama41/tfenv).

On mac simple install tfenv using brew.

```sh
brew install tfenv
```

Next install a terraform version.

```sh
tfenv install <version>
```

### AWS

To run the terraform scripts you need to have AWS keys.
Example file:

```sh
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
```

### Service linked roles

The gitlab runner ec2 instance needs the following sercice linked roles:

- AWSServiceRoleForAutoScaling
- AWSServiceRoleForEC2Spot

By default the ec2 instance is allowed to create the roles, by setting the option `allow_iam_service_linked_role_creation` to `false` you can deny the creation of roles by the instance. In that case you have to ensure the roles exists. You can create them manually or via terraform.

```hcl
resource "aws_iam_service_linked_role" "spot" {
  aws_service_name = "spot.amazonaws.com"
}

resource "aws_iam_service_linked_role" "autoscaling" {
  aws_service_name = "autoscaling.amazonaws.com"
}
```

### Configuration GitLab runner token

Currently register a new runner is a manual process. See the GitLab Runner [documentation](https://docs.gitlab.com/runner/register/index.html#docker) for more details.

```sh
docker run -it --rm gitlab/gitlab-runner register
```

Provide the details in the interactive terminal. Once done the token can be found in the GitLab runners section, choose edit to get the token or see the config.toml file.

## Usage

### Configuration

Update the variables in `terraform.tfvars` to your needs and add the following variables, see previous step for how to obtain the token.

```hcl
runner_name  = "NAME_OF_YOUR_RUNNER"
gitlab_url   = "GIT_LAB_URL"
runner_token  = "RUNNER_TOKEN"
```

The base image used to host the GitLab Runner agent is the latest available Amazon Linux HVM EBS AMI. In previous version of the module an hard coded list of AMI per region was available. This list is replaced by a search filter to find the latest AMI. By setting the filter for example to `amzn-ami-hvm-2018.03.0.20180622-x86_64-ebs` you can lock the version of the AMI.


### Usage module.

```hcl
module "gitlab-runner" {
  source = "npalm/gitlab-runner/aws"
  version = "1.0.0"

  aws_region              = "${var.aws_region}"
  environment             = "${var.environment}"
  ssh_public_key          = "${file("${var.ssh_key_file}")}"

  vpc_id                  = "${module.vpc.vpc_id}"
  subnet_ids_gitlab_runner = "${module.vpc.private_subnets}"
  subnet_id_runners       = "${element(module.vpc.private_subnets, 0)}"

  runners_name             = "${var.runner_name}"
  runners_gitlab_url       = "${var.gitlab_url}"
  runners_token            = "${var.runner_token}"

  # Optional
  runners_off_peak_timezone = "Europe/Amsterdam"
  runners_off_peak_periods  = "[\"* * 0-9,17-23 * * mon-fri *\", \"* * * * * sat,sun *\"]"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| allow_iam_service_linked_role_creation | Attach policy to runner instance to create service linked roles. | string | `true` | no |
| ami_filter | AMI filter to select the AMI used to host the gitlab runner agent. By default the pattern `amzn-ami-hvm-2018.03*-x86_64-ebs` is used for the name. Currently Amazon Linux 2 `amzn2-ami-hvm-2.0.????????-x86_64-ebs` looks *not* working for this configuration. | list | `<list>` | no |
| ami_owners | A list of owners used to select the AMI for the instance. | list | `<list>` | no |
| aws_region | AWS region. | string | - | yes |
| aws_zone | AWS availability zone (typically 'a', 'b', or 'c'). | string | `a` | no |
| cache_bucket_prefix | Prefix for s3 cache bucket name. | string | `` | no |
| cache_expiration_days | Number of days before cache objects expires. | string | `1` | no |
| cache_shared | Enables cache sharing between runners, false by default. | string | `false` | no |
| create_runners_iam_instance_profile |  | string | `true` | no |
| docker_machine_instance_type | Instance type used for the instances hosting docker-machine. | string | `m4.large` | no |
| docker_machine_options | Additional to set options for docker machine. Each element of the list should be key and value. E.g. '["amazonec2-zone=a"]' | list | `<list>` | no |
| docker_machine_spot_price_bid | Spot price bid. | string | `0.04` | no |
| docker_machine_user | User name for the user to create spot instances to host docker-machine. | string | `docker-machine` | no |
| docker_machine_version | Version of docker-machine. | string | `0.16.1` | no |
| enable_cloudwatch_logging | Enable or disable the CloudWatch logging. | string | `1` | no |
| environment | A name that identifies the environment, will used as prefix and for tagging. | string | - | yes |
| gitlab_runner_version | Version for the gitlab runner. | string | `11.8.0` | no |
| instance_role_json | Instance role json for the runner agent ec2 instance to override the default. | string | `` | no |
| instance_role_runner_json | Instance role json for the docker machine runners to override the default. | string | `` | no |
| instance_type | Instance type used for the gitlab-runner. | string | `t2.micro` | no |
| runners_concurrent | Concurrent value for the runners, will be used in the runner config.toml | string | `10` | no |
| runners_executor | The executor to use. Currently supports docker+machine or docker | string | `docker+machine` | no |
| runners_gitlab_url | URL of the gitlab instance to connect to. | string | - | yes |
| runners_iam_instance_profile_name | IAM instance profile name of the runners, will be used in the runner config.toml | string | `` | no |
| runners_idle_count | Idle count of the runners, will be used in the runner config.toml | string | `0` | no |
| runners_idle_time | Idle time of the runners, will be used in the runner config.toml | string | `600` | no |
| runners_image | Image to run builds, will be used in the runner config.toml | string | `docker:18.03.1-ce` | no |
| runners_limit | Limit for the runners, will be used in the runner config.toml | string | `0` | no |
| runners_monitoring | Enable detailed cloudwatch monitoring for spot instances. | string | `false` | no |
| runners_name | Name of the runner, will be used in the runner config.toml | string | - | yes |
| runners_off_peak_idle_count | Off peak idle count of the runners, will be used in the runner config.toml. | string | `0` | no |
| runners_off_peak_idle_time | Off peak idle time of the runners, will be used in the runner config.toml. | string | `0` | no |
| runners_off_peak_periods | Off peak periods of the runners, will be used in the runner config.toml. | string | `` | no |
| runners_off_peak_timezone | Off peak idle time zone of the runners, will be used in the runner config.toml. | string | `` | no |
| runners_output_limit | Set maximum build log size in kilobytes, by default set to 4096 (4MB) | string | `4096` | no |
| runners_post_build_script | Commands to be executed on the Runner just after executing the build, but before executing after_script. | string | `` | no |
| runners_pre_build_script | Script to execute in the pipeline just before the build, will be used in the runner config.toml | string | `` | no |
| runners_pre_clone_script | Commands to be executed on the Runner before cloning the Git repository. this can be used to adjust the Git client configuration first, for example. | string | `` | no |
| runners_privilled | Runners will run in privilled mode, will be used in the runner config.toml | string | `true` | no |
| runners_request_concurrency | Limit number of concurrent requests for new jobs from GitLab (default 1) | string | `1` | no |
| runners_root_size | Runnner instance root size in GB. | string | `16` | no |
| runners_token | Token for the runner, will be used in the runner config.toml | string | - | yes |
| runners_use_private_address | Restrict runners to use only private address | string | `true` | no |
| ssh_public_key | Public SSH key used for the gitlab-runner ec2 instance. | string | - | yes |
| subnet_id_runners | Subnet used to hosts the docker-machine runners. | string | - | yes |
| subnet_ids_gitlab_runner | Subnet used for hosting the gitlab-runner. | list | - | yes |
| tags | Map of tags that will be added to created resources. By default resources will be tagged with name and environnemnt. | map | `<map>` | no |
| userdata_post_install | User-data script snippet to insert after gitlab-runner install | string | `` | no |
| userdata_pre_install | User-data script snippet to insert before gitlab-runner install | string | `` | no |
| vpc_id | The VPC that is used for the instances. | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| runner_agent_role | ARN of the rule used for the ec2 instance for the GitLab runner agent. |
| runner_as_group_name | Name of the autoscaling group for the gitlab-runner instance |
| runner_cache_bucket_arn | ARN of the S3 for the build cache. |

## Example

An example is provided, execute the following steps to run the sample. Ensure your AWS and Terraform environment is set up correctly. All commands below are supposed to be run inside the directory `example`.

### AWS keys

Keys are generated by terraform and stored in a directory `generated` in the example directory.

### Configure GitLab

Register a new runner:

```sh
docker run -it --rm gitlab/gitlab-runner register
```

Once done, lookup the token in GitLab and update the `terraform.tfvars` file.

## Create runner

Run `terraform init` to initialize terraform. Next you can run `terraform plan` to inspect the resources that will be created.

To create the runner run:

```sh
terraform apply
```

To destroy runner:

```sh
terraform destroy
```

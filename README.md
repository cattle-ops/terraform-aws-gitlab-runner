# Terraform module for GitLab auto scaling runners on Spot instances

This repo contains a terraform module and example to run a [GitLab CI multi runner](https://docs.gitlab.com/runner/) on AWS Spot instances.
This repo contains a terraform sample script to create GitLab CI multi runners on AWS spot instances. The setup is based on the blog post: [Autoscale GitLab CI runners and save 90% on EC2 costs] (https://about.gitlab.com/2017/11/23/autoscale-ci-runners/)

The created runner will have by default a shared cache in S3 and logging is streamed to CloudWatch.

## Prerequisites

### Terraform
Ensure you have Terraform installed, see `.terraform-version` for the used version.

On mac simple install tfenv using brew.
```
brew install tfenv
```
Next intall a terraform version.
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
Provice the details in teh interactive terminal. Once done the token cen found in the GitLab runners section, choose edit to get the token.


## Usage

### Configuration
Update the variables in `terraform.tfvars` to your needs and add the folling variables, see prevous step for how to obtain the token.
```
runner_name = "NAME_OF_YOUR_RUNNER"
gitlab_url = "GIT_LAB_URL"
runner_token = "RUNNER_TOKEN"
```


### Usage module.
```
module "runner" {
  source = "https://github.com/npalm/tf-aws-gitlab-runner.git"

  aws_region       = "<region-to-use>"
  ssh_key_file_pub = "<file-contains-public-key"

  vpc_id                  = "<vpc-id>"
  subnet_id_gitlab_runner = "<subnet-for-runner"
  subnet_id_runners       = "<subnet-for-docker-machine-runners"

  runner_name       = "<name-of-the-runner"
  runner_gitlab_url = "<gitlab-url>"
  runner_token      = "<token-of-the-runner"
}
```

All variables and defaults:

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| amazon_optimized_amis | AMI map per region-zone for the gitlab-runner instance AMI. | map | `<map>` | no |
| aws_region | AWS region. | string | - | yes |
| cache_expiration_days | Number of days before cache objects expires. | string | `1` | no |
| cache_user | User name of the user to create to write and read to the s3 cache. | string | `cache_user` | no |
| docker_machine_instance_type | Instance type used for the instances hosting docker-machine. | string | `m3.large` | no |
| docker_machine_spot_price_bid | Spot price bid. | string | `0.03` | no |
| docker_machine_user | User name for the user to create spot instances to host docker-machine. | string | `docker-machine` | no |
| environment | A name that indentifies the environment, will used as prefix and for taggin. | string | - | yes |
| instance_type | Instance type used for the gitlab-runner. | string | `t2.micro` | no |
| runners_concurrent | Concurrent value for the runners, will be used in the runner config.toml | string | `10` | no |
| runners_gitlab_url | URL of the gitlab instance to connect to. | string | - | yes |
| runners_idle_count | Idle count of the runners, will be used in the runner config.toml | string | `0` | no |
| runners_idle_time | Idle time of the runners, will be used in the runner config.toml | string | `600` | no |
| runners_limit | Limit for the runners, will be used in the runner config.toml | string | `1` | no |
| runners_name | Name of the runner, will be used in the runner config.toml | string | - | yes |
| runners_privilled | Runners will run in privilled mode, will be used in the runner config.toml | string | `true` | no |
| runners_token | Token for the runner, will be used in the runner config.toml | string | - | yes |
| ssh_key_file_pub | File contians the public key used for the gitlab-runner. | string | - | yes |
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
Run `terraform init` to inialize terraform. Next you can run `terraform plan` to inspect the resources that will be create.

To create the runner run:
```
terrafrom apply
```
To destroy runner:
```
terraform desroy
```

## Notes:
- A user is create for the gitlab-runner / docker-machine to create ec2 instances, the permissions are NOT very restrictive.

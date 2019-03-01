[![Build Status](https://travis-ci.com/npalm/terraform-aws-gitlab-runner.svg?branch=master)](https://travis-ci.com/npalm/terraform-aws-gitlab-runner)

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

By default the runner is registered the first time. In previous version this was a manual process. The manual process is still supported but will be removed in future releases. The runner token will be stored in the parameter store.

To register the runner automatically set the variable `gitlab_runner_registration_config["token"]` which you can find in your GitLab project, group or global settings. For a generic runner you find the token in the admin section. By default the runner will be locked to project, not run untagged. Below an example of the configuration map.

```
  gitlab_runner_registration_config = {
    registration_token = "<registration token>"
    tag_list           = "<your tags, comma separated"
    description        = "<some description>"
    locked_to_project  = "true"
    run_untagged       = "false"
    maximum_timeout    = "3600"
  }
```

For migration to the new setup, just simply add the runner token to the parameter store. Once the runner is started it will lookup the parameter store for an already register one. If the value is null a new runner will be created.

```
# set the following variables, look up the variables in your terraform config.
# see your terraform variables to fill in the vars below.
aws-region=<${var.aws_region}>
token=<runner-token-see-your-gitlab-runner>
parameter-name=<${var.environment}>-<${var.secure_parameter_store_runner_token_key}>

aws ssm put-parameter --overwrite --type SecureString  --name "${parameter-name}" --value ${token} --region "${aws-region}"
```
Once you have created the parameter, you have to remove the variable `runners_token` from your config. Then next time your gitlab runner instance is created it look up the token from the paramater store.

Finally the runner still support the manual runner creation, no changes are required. Please keep in mind that this setup will be removed.


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
| aws_region | AWS region. | string | `eu-west-1` | no |
| environment | A name that indentifies the environment, will used as prefix and for taggin. | string | `ci-runners` | no |
| gitlab_url | URL of the gitlab instance to connect to. | string | - | yes |
| private_ssh_key_filename |  | string | `generated/id_rsa` | no |
| public_ssh_key_filename |  | string | `generated/id_rsa.pub` | no |
| runner_name | Name of the runner, will be used in the runner config.toml | string | - | yes |
| runner_token | Token for the runner, will be used in the runner config.toml | string | - | yes |

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

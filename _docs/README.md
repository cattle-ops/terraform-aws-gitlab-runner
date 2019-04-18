[![Build Status](https://travis-ci.com/npalm/terraform-aws-gitlab-runner.svg?branch=master)](https://travis-ci.com/npalm/terraform-aws-gitlab-runner)
[![Gitter](https://badges.gitter.im/terraform-aws-gitlab-runner/Lobby.svg)](https://gitter.im/terraform-aws-gitlab-runner/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

# Terraform module for GitLab auto scaling runners on AWS spot instances

> *NEW*: The runner will register itself automatically to GitLab. No need to register the runner first, see also the [examples](./examples)

This repo contains a Terraform module and examples to run a [GitLab CI multi runner](https://docs.gitlab.com/runner/) on AWS Spot instances. See the blog post at [040code](https://040code.github.io/2017/12/09/runners-on-the-spot/) for a detailed description of the setup.

![GitLab Runners](https://github.com/npalm/assets/raw/master/images/2017-12-06_gitlab-multi-runner-aws.png)

The setup is based on the blog post: [Auto scale GitLab CI runners and save 90% on EC2 costs](https://about.gitlab.com/2017/11/23/autoscale-ci-runners/) The gitlab-ci runners that this project creates will be configured to use a shared cache via S3 by default. Additionally their logs will be streamed to CloudWatch. The s3 stored cache expiration is configurable and is set to expire in X days by default. Logging can be disabled. The accompanying post mentions that you have to register the the runner before running the Terraform scripts. Since version 3+ this is no longer required. You can simply define the runner configuration, including the runner registration token, via terraform.

In addition to the auto scaling option (docker+machine executor) the docker executor is supported for a single node.

## Prerequisites

### Terraform

Ensure you have Terraform installed, see `.terraform-version` for the used version. A handy tool to mange your Terraform version is [tfenv](https://github.com/kamatama41/tfenv).

On macOS it is simple to install `tfenv` using brew.

```sh
brew install tfenv
```

Next install a Terraform version.

```sh
tfenv install <version>
```

### AWS

Export your AWS Security Credentials:

```sh
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
```

### Service linked roles

The gitlab runner EC2 instance requires the following service linked roles:

- AWSServiceRoleForAutoScaling
- AWSServiceRoleForEC2Spot

By default the EC2 instance is allowed to create the required roles, but this can be disabled by setting the option `allow_iam_service_linked_role_creation` to `false`. If disabled you must ensure the roles exist. You can create them manually or via Terraform.

```hcl
resource "aws_iam_service_linked_role" "spot" {
  aws_service_name = "spot.amazonaws.com"
}

resource "aws_iam_service_linked_role" "autoscaling" {
  aws_service_name = "autoscaling.amazonaws.com"
}
```

### GitLab runner token configuration

By default the runner is registered on initial deployment. In previous versions of this module this was a manual process. The manual process is still supported but will be removed in future releases. The runner token will be stored in the parameter store. See [example](examples/runner-pre-registered/) for more details.

To register the runner automatically set the variable `gitlab_runner_registration_config["token"]`. This token value can be found in your GitLab project, group, or global settings. For a generic runner you can find the token in the admin section. By default the runner will be locked to the target project, not run untagged. Below is an example of the configuration map.

```hcl
gitlab_runner_registration_config = {
  registration_token = "<registration token>"
  tag_list           = "<your tags, comma separated>"
  description        = "<some description>"
  locked_to_project  = "true"
  run_untagged       = "false"
  maximum_timeout    = "3600"
}
```

For migration to the new setup simply add the runner token to the parameter store. Once the runner is started it will lookup the required values via the parameter store. If the value is `null` a new runner will be created.

```sh
# set the following variables, look up the variables in your Terraform config.
# see your Terraform variables to fill in the vars below.
aws-region=<${var.aws_region}>
token=<runner-token-see-your-gitlab-runner>
parameter-name=<${var.environment}>-<${var.secure_parameter_store_runner_token_key}>

aws ssm put-parameter --overwrite --type SecureString  --name "${parameter-name}" --value ${token} --region "${aws-region}"
```

Once you have created the parameter, you must remove the variable `runners_token` from your config. The next time your gitlab runner instance is created it will look up the token from the SSM parameter store.

Finally, the runner still supports the manual runner creation. No changes are required. Please keep in mind that this setup will be removed in future releases.

## Usage

### Configuration

Update the variables in `terraform.tfvars` according to your needs and add the following variables. See the previous step for instructions on how to obtain the token.

```hcl
runner_name  = "NAME_OF_YOUR_RUNNER"
gitlab_url   = "GITLAB_URL"
runner_token = "RUNNER_TOKEN"
```

The base image used to host the GitLab Runner agent is the latest available Amazon Linux HVM EBS AMI. In previous versions of this module a hard coded list of AMIs per region was provided. This list has been replaced by a search filter to find the latest AMI. Setting the filter to `amzn-ami-hvm-2018.03.0.20180622-x86_64-ebs` will allow you to version lock the target AMI.

### Usage module

```hcl
module "runner" {
  source = "npalm/gitlab-runner/aws"
  version = "3.2.0"

  aws_region      = "${var.aws_region}"
  environment     = "${var.environment}"
  ssh_public_key  = "${file("${var.ssh_key_file}")}"

  vpc_id                   = "${module.vpc.vpc_id}"
  subnet_ids_gitlab_runner = "${module.vpc.private_subnets}"
  subnet_id_runners        = "${element(module.vpc.private_subnets, 0)}"

  runners_name       = "my-spot-runner"
  runners_gitlab_url = "https://www.gitlab.com"

  gitlab_runner_registration_config = {
    registration_token = "<YOUR_TOKEN>"
    tag_list           = "docker_spot_runner"
    description        = "Docker AWS Spot runner"
    locked_to_project  = "true"
    run_untagged       = "false"
    maximum_timeout    = "3600"
  }

  runners_off_peak_timezone   = "Europe/Amsterdam"
  runners_off_peak_idle_count = 0
  runners_off_peak_idle_time  = 60

  # working 9 to 5 :)
  runners_off_peak_periods = "[\"* * 0-9,17-23 * * mon-fri *\", \"* * * * * sat,sun *\"]"
}
```

## Example

A few [examples](examples) are provided. Use the following steps to deploy. Ensure your AWS and Terraform environment is set up correctly. All commands below should be run from the `terraform-aws-gitlab-runner/examples` directory.

### AWS keys

SSH keys are generated by Terraform and stored in the `generated` directory of each example directory.

### Configure GitLab

*This step is not needed anymore* Configure you runner via `gitlab_runner_registration_config`. Configuring GitLab via the step below is only needed when you choose to create the token manually and set the `runners_token` variable.

Register a new runner:

```sh
docker run -it --rm gitlab/gitlab-runner register
```

Once done, lookup the token in GitLab and update the `terraform.tfvars` file.

## Create runner

Run `terraform init` to initialize Terraform. Next you can run `terraform plan` to inspect the resources that will be created.

To create the runner run:

```sh
terraform apply
```

To destroy runner:

```sh
terraform destroy
```

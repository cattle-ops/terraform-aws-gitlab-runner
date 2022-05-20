[![Terraform registry](https://img.shields.io/github/v/release/npalm/terraform-aws-gitlab-runner?label=Terraform%20Registry)](https://registry.terraform.io/modules/npalm/gitlab-runner/aws/) [![Gitter](https://badges.gitter.im/terraform-aws-gitlab-runner/Lobby.svg)](https://gitter.im/terraform-aws-gitlab-runner/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge) [![Actions](https://github.com/npalm/terraform-aws-gitlab-runner/workflows/Verify/badge.svg)](https://github.com/npalm/terraform-aws-gitlab-runner/actions)

# Terraform module for GitLab auto scaling runners on AWS spot instances <!-- omit in toc -->

- [The module](#the-module)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
- [Examples](#examples)
- [Contributors ✨](#contributors-)

## The module

This [Terraform](https://www.terraform.io/) modules creates a [GitLab CI runner](https://docs.gitlab.com/runner/). A blog post describes the original version of the the runner. See the post at [040code](https://040code.github.io/2017/12/09/runners-on-the-spot/). The original setup of the module is based on the blog post: [Auto scale GitLab CI runners and save 90% on EC2 costs](https://about.gitlab.com/2017/11/23/autoscale-ci-runners/).

> BREAKING CHANGE: The module is upgraded to Terraform AWS provider 4.x. All new development will only support the new AWS Terraform provider. We keep a branch `terraform-aws-provider-3` to witch we welcome backports to AWS Terraform 3.x provider. Besides reviewing PR's we will do not any active checking on maintance on this branch. We strongly advise to update your deployment to the new provider version. For more details about upgrading see the [upgrade guide](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/version-4-upgrade).

> BREAKING CHANGE: By default AWS metadata service ((IMDSv2)[https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html]) is enabled and required for both the agent instance and the docker machine instance. For docker machine this require the GitLab managed docker machines distribution is used. Which the module usages by default.

The runners created by the module use spot instances by default for running the builds using the `docker+machine` executor.

- Shared cache in S3 with life cycle management to clear objects after x days.
- Logs streamed to CloudWatch.
- Runner agents registered automatically.

The name of the runner agent and runner is set with the overrides variable. Adding an agent runner name tag does not work.

```hcl
...
overrides  = {
  name_sg                     = ""
  name_runner_agent_instance  = "Gitlab Runner Agent"
  name_docker_machine_runners = "Gitlab Runner Terraform"
  name_iam_objects = "gitlab-runner"
}

//this doesn't work
agent_tags = merge(local.my_tags, map("Name", "Gitlab Runner Agent"))
```

The runner supports 3 main scenarios:

### GitLab CI docker-machine runner - one runner agent

In this scenario the runner agent is running on a single EC2 node and runners are created by [docker machine](https://docs.gitlab.com/runner/configuration/autoscale.html) using spot instances. Runners will scale automatically based on the configuration. The module creates a S3 cache by default, which is shared across runners (spot instances).

![runners-default](https://github.com/npalm/assets/raw/main/images/terraform-aws-gitlab-runner/runner-default.png)

### GitLab CI docker-machine runner - multiple runner agents

In this scenario the multiple runner agents can be created with different configuration by instantiating the module multiple times. Runners will scale automatically based on the configuration. The S3 cache can be shared across runners by managing the cache outside of the module.

![runners-cache](https://github.com/npalm/assets/raw/main/images/terraform-aws-gitlab-runner/runner-cache.png)

### GitLab Ci docker runner

In this scenario _not_ docker machine is used but docker to schedule the builds. Builds will run on the same EC2 instance as the agent. No auto scaling is supported.

![runners-docker](https://github.com/npalm/assets/raw/main/images/terraform-aws-gitlab-runner/runner-docker.png)

## Prerequisites

### Terraform

Ensure you have Terraform installed. The modules is based on Terraform 0.11, see `.terraform-version` for the used version. A handy tool to mange your Terraform version is [tfenv](https://github.com/kamatama41/tfenv).

On macOS it is simple to install `tfenv` using `brew`.

```sh
brew install tfenv
```

Next install a Terraform version.

```sh
tfenv install <version>
```

### AWS

Ensure you have setup your AWS credentials. The module requires access to IAM, EC2, CloudWatch, S3 and SSM.

### JQ & AWS CLI

In order to be able to destroy the module, you will need to run from a host with both `jq` and `aws` installed and accessible in the environment.

On macOS it is simple to install them using `brew`.

```sh
brew install jq awscli
```

### Service linked roles

The GitLab runner EC2 instance requires the following service linked roles:

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

By default the runner is registered on initial deployment. In previous versions of this module this was a manual process. The manual process is still supported but will be removed in future releases. The runner token will be stored in the AWS SSM parameter store. See [example](examples/runner-pre-registered/) for more details.

To register the runner automatically set the variable `gitlab_runner_registration_config["registration_token"]`. This token value can be found in your GitLab project, group, or global settings. For a generic runner you can find the token in the admin section. By default the runner will be locked to the target project, not run untagged. Below is an example of the configuration map.

```hcl
gitlab_runner_registration_config = {
  registration_token = "<registration token>"
  tag_list           = "<your tags, comma separated>"
  description        = "<some description>"
  locked_to_project  = "true"
  run_untagged       = "false"
  maximum_timeout    = "3600"
  access_level       = "<not_protected OR ref_protected, ref_protected runner will only run on pipelines triggered on protected branches. Defaults to not_protected>"
}
```

For migration to the new setup simply add the runner token to the parameter store. Once the runner is started it will lookup the required values via the parameter store. If the value is `null` a new runner will be registered and a new token created/stored.

```sh
# set the following variables, look up the variables in your Terraform config.
# see your Terraform variables to fill in the vars below.
aws-region=<${var.aws_region}>
token=<runner-token-see-your-gitlab-runner>
parameter-name=<${var.environment}>-<${var.secure_parameter_store_runner_token_key}>

aws ssm put-parameter --overwrite --type SecureString  --name "${parameter-name}" --value ${token} --region "${aws-region}"
```

Once you have created the parameter, you must remove the variable `runners_token` from your config. The next time your GitLab runner instance is created it will look up the token from the SSM parameter store.

Finally, the runner still supports the manual runner creation. No changes are required. Please keep in mind that this setup will be removed in future releases.

### Auto Scaling Group Instance Termination

The Auto Scaling Group may be configured with a
[lifecycle hook](https://docs.aws.amazon.com/autoscaling/ec2/userguide/lifecycle-hooks.html)
that executes a provided Lambda function when the runner is terminated to
terminate additional instances that were spawned.

The use of the termination lifecycle can be toggled using the
`asg_termination_lifecycle_hook_create` variable.

When using this feature, a `builds/` directory relative to the root module will
persist that contains the packaged Lambda function.

### Access runner instance

A few option are provided to access the runner instance:

1.  Provide a public ssh key to access the runner by setting \`\`.
2.  Provide a EC2 key pair to access the runner by setting \`\`.
3.  Access via the Session Manager (SSM) by setting `enable_runner_ssm_access` to `true`. The policy to allow access via SSM is not very restrictive.
4.  By setting none of the above, no keys or extra policies will be attached to the instance. You can still configure you own policies by attaching them to `runner_agent_role_arn`.

### GitLab runner cache

By default the module creates a a cache for the runner in S3. Old objects are automatically removed via a configurable life cycle policy on the bucket.

Creation of the bucket can be disabled and managed outside this module. A good use case is for sharing the cache across multiple runners. For this purpose the cache is implemented as a sub module. For more details see the [cache module](https://github.com/npalm/terraform-aws-gitlab-runner/tree/develop/cache). An example implementation of this use case can be found in the [runner-public](https://github.com/npalm/terraform-aws-gitlab-runner/tree/__GIT_REF__/examples/runner-public) example.



## Usage

### Configuration

Update the variables in `terraform.tfvars` according to your needs and add the following variables. See the previous step for instructions on how to obtain the token.

```hcl
runner_name  = "NAME_OF_YOUR_RUNNER"
gitlab_url   = "GITLAB_URL"
runner_token = "RUNNER_TOKEN"
```

The base image used to host the GitLab Runner agent is the latest available Amazon Linux 2 HVM EBS AMI. In previous versions of this module a hard coded list of AMIs per region was provided. This list has been replaced by a search filter to find the latest AMI. Setting the filter to `amzn2-ami-hvm-2.0.20200207.1-x86_64-ebs` will allow you to version lock the target AMI.

### Scenario: Basic usage

Below is a basic examples of usages of the module. Regarding the dependencies such as a VPC and SSH keys, have a look at the [default example](https://github.com/npalm/terraform-aws-gitlab-runner/tree/develop/examples/runner-default).

```hcl
module "runner" {
  # https://registry.terraform.io/modules/npalm/gitlab-runner/aws/
  source  = "npalm/gitlab-runner/aws"

  aws_region  = "eu-west-1"
  environment = "spot-runners"

  ssh_public_key = local_file.public_ssh_key.content

  vpc_id                   = module.vpc.vpc_id
  subnet_ids_gitlab_runner = module.vpc.private_subnets
  subnet_id_runners        = element(module.vpc.private_subnets, 0)

  runners_name       = "docker-default"
  runners_gitlab_url = "https://gitlab.com"

  gitlab_runner_registration_config = {
    registration_token = "my-token
    tag_list           = "docker"
    description        = "runner default"
    locked_to_project  = "true"
    run_untagged       = "false"
    maximum_timeout    = "3600"
  }

}
```

### Removing the module

Remove the module from your Terraform code and deregister the runner manually from your Gitlab instance.
### Scenario: Multi-region deployment

Name clashes due to multi-region deployments for global AWS ressources create by this module (IAM, S3) can be avoided by including a distinguishing region specific prefix via the _cache_bucket_prefix_ string respectively via _name_iam_objects_ in the _overrides_ map. A simple example for this would be to set _region-specific-prefix_ to the AWS region the module is deployed to.



```hcl
module "runner" {
  # https://registry.terraform.io/modules/npalm/gitlab-runner/aws/
  source  = "npalm/gitlab-runner/aws"

  aws_region  = "eu-west-1"
  environment = "spot-runners"

  ssh_public_key = local_file.public_ssh_key.content

  vpc_id                   = module.vpc.vpc_id
  subnet_ids_gitlab_runner = module.vpc.private_subnets
  subnet_id_runners        = element(module.vpc.private_subnets, 0)

  runners_name       = "docker-default"
  runners_gitlab_url = "https://gitlab.com"

  gitlab_runner_registration_config = {
    registration_token = "my-token
    tag_list           = "docker"
    description        = "runner default"
    locked_to_project  = "true"
    run_untagged       = "false"
    maximum_timeout    = "3600"
  }

  overrides = {
    name_iam_objects = "<region-specific-prefix>-gitlab-runner-iam"
  }

  cache_bucket_prefix = "<region-specific-prefix>"
}
```

## Examples

A few [examples](https://github.com/npalm/terraform-aws-gitlab-runner/tree/develop/examples/) are provided. Use the following steps to deploy. Ensure your AWS and Terraform environment is set up correctly. All commands below should be run from the `terraform-aws-gitlab-runner/examples/<example-dir>` directory. Don't forget to remove the runners manually from your Gitlab instance as soon as your are done.

### SSH keys

SSH keys are generated by Terraform and stored in the `generated` directory of each example directory.

### Versions

The version of Terraform is locked down via tfenv, see the `.terraform-version` file for the expected versions. Providers are locked down as well in the `providers.tf` file.

### Configure

The examples are configured with defaults that should work in general. The examples are in general configured for the region Ireland `eu-west-1`. The only parameter that needs to be provided is the GitLab registration token. The token can be found in GitLab in the runner section (global, group or repo scope). Create a file `terrafrom.tfvars` and the registration token.

    registration_token = "MY_TOKEN"

### Run

Run `terraform init` to initialize Terraform. Next you can run `terraform plan` to inspect the resources that will be created.

To create the runner, run:

```sh
terraform apply
```

To destroy the runner, run:

```sh
terraform destroy
```


## Contributors ✨

This project exists thanks to all the people who contribute.

<a href="https://github.com/npalm/terraform-aws-gitlab-runner/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=npalm/terraform-aws-gitlab-runner" />
</a>

Made with [contributors-img](https://contrib.rocks).


<!-- BEGIN_TF_DOCS -->

<!-- END_TF_DOCS -->

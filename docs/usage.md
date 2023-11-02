# Usage

Common pitfalls are documented in [pitfalls.md](pitfalls.md).

## Configuration

The examples are configured with defaults that should work in general. The examples are in general configured for the
region Ireland `eu-west-1`. The only parameter that needs to be provided is the GitLab are the registration token and the
URL of your GitLab instance. The token can be found in GitLab in the runner section (global, group or repo scope).
Create a file `terraform.tfvars` and the registration token.

```hcl
registration_token = "MY_TOKEN"
gitlab_url   = "https://my.gitlab.instance/"
```

The base image used to host the GitLab Runner agent is the latest available Amazon Linux 2 HVM EBS AMI. In previous versions of
this module a hard coded list of AMIs per region was provided. This list has been replaced by a search filter to find the latest
AMI. Setting the filter to `amzn2-ami-hvm-2.0.20200207.1-x86_64-ebs` will allow you to version lock the target AMI if needed.

> 💥  **If you are using GitLab >= 16.0.0**: `registration_token` will be deprecated!

>GitLab >= 16.0.0 has removed the `registration_token` since they are working on a [new token architecture](https://docs.gitlab.com/ee/architecture/blueprints/runner_tokens/). This module handle these changes, you need to provide a personal access token with `api` scope for the runner to authenticate itself.

>The workflow is as follows ([migration steps](https://github.com/cattle-ops/terraform-aws-gitlab-runner/pull/876)):
>1. The runner make an API call (with the access token) to create a new runner on GitLab depending on its type (`instance`, `group` or `project`).
>2. GitLab answers with a token prefixed by `glrt-` and we put it in SSM.
>3. The runner will get the config from `/etc/gitlab-runner/config.toml` and will listen for new jobs from your GitLab instance.

## Install the module

Run `terraform init` to initialize Terraform. Next you can run `terraform plan` to inspect the resources that will be created.

To create the runner, run:

```sh
terraform apply
```

To destroy the runner, run:

```sh
terraform destroy
```

## Scenarios

### Scenario: Basic usage on GitLab **< 16.0.0**

Below is a basic examples of usages of the module. Regarding the dependencies such as a VPC, have a look at the [default example](https://github.com/cattle-ops/terraform-aws-gitlab-runner/tree/main/examples/runner-default).

```hcl
module "runner" {
# https://registry.terraform.io/modules/cattle-ops/gitlab-runner/aws/
source  = "cattle-ops/gitlab-runner/aws"

environment = "basic"

vpc_id    = module.vpc.vpc_id
subnet_id = element(module.vpc.private_subnets, 0)

runner_gitlab = {
url = "https://gitlab.com"
}

runner_gitlab_registration_config = {
registration_token = "my-token"
tag_list           = "docker"
description        = "runner default"
locked_to_project  = "true"
run_untagged       = "false"
maximum_timeout    = "3600"
}

runner_worker_docker_machine_instance = {
subnet_ids = module.vpc.private_subnets
}
}
```

### Scenario: Basic usage on GitLab **>= 16.0.0**

Below is a basic examples of usages of the module if your GitLab instance version is >= 16.0.0.

```hcl
module "runner" {
  # https://registry.terraform.io/modules/cattle-ops/gitlab-runner/aws/
  source  = "cattle-ops/gitlab-runner/aws"

  aws_region  = "eu-west-1"
  environment = "spot-runners"

  vpc_id                   = module.vpc.vpc_id
  subnet_ids_gitlab_runner = module.vpc.private_subnets
  subnet_id_runners        = element(module.vpc.private_subnets, 0)

  runners_name       = "docker-default"
  runners_gitlab_url = "https://gitlab.com"

  runner_gitlab_access_token_secure_parameter_store_name = "gitlab_access_token_ssm__name"


  runner_gitlab_registration_config = {
    type               = "instance" # or "group" or "project"
    # group_id           = 1234 # for "group"
    # project_id         = 5678 # for "project"
    tag_list           = "docker"
    description        = "runner default"
    locked_to_project  = "true"
    run_untagged       = "false"
    maximum_timeout    = "3600"
  }

}
```

### Scenario: Multi-region deployment

Name clashes due to multi-region deployments for global AWS resources create by this module (IAM, S3) can be avoided by including a
distinguishing region specific prefix via the _cache_bucket_prefix_ string respectively via _name_iam_objects_ in the _overrides_
map. A simple example for this would be to set _region-specific-prefix_ to the AWS region the module is deployed to.

```hcl
module "runner" {
# https://registry.terraform.io/modules/cattle-ops/gitlab-runner/aws/
source  = "cattle-ops/gitlab-runner/aws"

environment = "multi-region-1"
iam_object_prefix = "<region-specific-prefix>-gitlab-runner-iam"

vpc_id    = module.vpc.vpc_id
subnet_id = element(module.vpc.private_subnets, 0)

runner_gitlab = {
url = "https://gitlab.com"
}

runner_gitlab_registration_config = {
registration_token = "my-token"
tag_list           = "docker"
description        = "runner default"
locked_to_project  = "true"
run_untagged       = "false"
maximum_timeout    = "3600"
}

runner_worker_cache = {
bucket_prefix = "<region-specific-prefix>"
}

runner_worker_docker_machine_instance = {
subnet_ids = module.vpc.private_subnets
}
}
```

### Scenario: Use of Spot Fleet

Since spot instances can be taken over by AWS depending on the instance type and AZ you are using, you may want multiple instances
types in multiple AZs. This is where spot fleets come in, when there is no capacity on one instance type and one AZ, AWS will take
the next instance type and so on. This update has been possible since the
[fork](https://gitlab.com/cki-project/docker-machine/-/tree/v0.16.2-gitlab.19-cki.2) of docker-machine supports spot fleets.

We have seen that the [fork](https://gitlab.com/cki-project/docker-machine/-/tree/v0.16.2-gitlab.19-cki.2) of docker-machine this
module is using consume more RAM using spot fleets. For comparison, if you launch 50 machines in the same time, it consumes
~1.2GB of RAM. In our case, we had to change the `instance_type` of the runner from `t3.micro` to `t3.small`.

#### Configuration example

```hcl
module "runner" {
# https://registry.terraform.io/modules/cattle-ops/gitlab-runner/aws/
source  = "cattle-ops/gitlab-runner/aws"

environment = "spot-fleet"

vpc_id    = module.vpc.vpc_id
subnet_id = element(module.vpc.private_subnets, 0)

runner_gitlab = {
url = "https://gitlab.com"
}

runner_gitlab_registration_config = {
registration_token = "my-token"
tag_list           = "docker"
description        = "runner default"
locked_to_project  = "true"
run_untagged       = "false"
maximum_timeout    = "3600"
}

runner_worker = {
type = "docker+machine"
}

runner_worker_docker_machine_fleet = {
enable = true
}

runner_worker_docker_machine_instance = {
types = ["t3a.medium", "t3.medium", "t2.medium"]
subnet_ids = module.vpc.private_subnets
}
}
```

## Examples

A few [examples](https://github.com/cattle-ops/terraform-aws-gitlab-runner/tree/main/examples/) are provided. Use the
following steps to deploy. Ensure your AWS and Terraform environment is set up correctly. All commands below should be
run from the `terraform-aws-gitlab-runner/examples/<example-dir>` directory. Don't forget to remove the runners
manually from your Gitlab instance as soon as your are done.

## Concepts

### Service linked roles

The GitLab runner EC2 instance requires the following service linked roles:

- AWSServiceRoleForAutoScaling
- AWSServiceRoleForEC2Spot

By default, the EC2 instance is allowed to create the required roles, but this can be disabled by setting the option
`allow_iam_service_linked_role_creation` to `false`. If disabled you must ensure the roles exist. You can create them manually or
via Terraform.

```hcl
resource "aws_iam_service_linked_role" "spot" {
  aws_service_name = "spot.amazonaws.com"
}

resource "aws_iam_service_linked_role" "autoscaling" {
  aws_service_name = "autoscaling.amazonaws.com"
}
```

### KMS keys

If a KMS key is set via `kms_key_id`, make sure that you also give proper access to the key. Otherwise, you might
get errors, e.g. the build cache can't be decrypted or logging via CloudWatch is not possible. For a CloudWatch
example checkout [kms-policy.json](https://github.com/cattle-ops/terraform-aws-gitlab-runner/blob/main/policies/kms-policy.json)

### GitLab runner token configuration

By default, the runner is registered on initial deployment. In previous versions of this module this was a manual process. The
manual process is still supported but will be removed in future releases. The runner token will be stored in the AWS SSM parameter
store. See [example](../examples/runner-pre-registered) for more details.

To register the runner automatically set the variable `gitlab_runner_registration_config["registration_token"]`. This token value
can be found in your GitLab project, group, or global settings. For a generic runner you can find the token in the admin section.
By default, the runner will be locked to the target project and not run untagged jobs. Below is an example of the configuration map.

```hcl
runner_gitlab_registration_config = {
  registration_token = "<registration token>"
  tag_list           = "<your tags, comma separated>"
  description        = "<some description>"
  locked_to_project  = "true"
  run_untagged       = "false"
  maximum_timeout    = "3600"
  # ref_protected runner will only run on pipelines triggered on protected branches. Defaults to not_protected
  access_level       = "<not_protected OR ref_protected>"
}
```

The registration token can also be read in via SSM parameter store. If no registration token is passed in, the module
will look up the token in the SSM parameter store at the location specified by
`runner_gitlab_registration_token_secure_parameter_store_name`.

For migration to the new setup simply add the runner token to the parameter store. Once the runner is started it will look up the
required values via the parameter store. If the value is `null` a new runner will be registered and a new token created/stored.

```sh
# set the following variables, look up the variables in your Terraform config.
# see your Terraform variables to fill in the vars below.
aws-region=<${var.aws_region}>
token=<runner-token-see-your-gitlab-runner>
parameter-name=<${var.environment}>-<${var.secure_parameter_store_runner_token_key}>

aws ssm put-parameter --overwrite --type SecureString  --name "${parameter-name}" --value ${token} --region "${aws-region}"
```

Once you have created the parameter, you must remove the variable `runner_gitlab.registration_token` from your config. The next
time your GitLab runner instance is created it will look up the token from the SSM parameter store.

Finally, the runner still supports the manual runner creation. No changes are required. Please keep in mind that this setup will be
removed in future releases.

### Auto Scaling Group

#### Scheduled scaling

When `runner_schedule_enable=true`, the `runner_schedule_config` block can be used to scale the Auto Scaling group.

Scaling may be defined with one `scale_out_*` scheduled action and/or one `scale_in_*` scheduled action.

For example:

```hcl
  module "runner" {
    # ...
    runner_schedule_enable = true
    runner_schedule_config = {
      # Configure optional scale_out scheduled action
      scale_out_recurrence = "0 8 * * 1-5"
      scale_out_count      = 1 # Default for min_size, desired_capacity and max_size
      # Override using: scale_out_min_size, scale_out_desired_capacity, scale_out_max_size

      # Configure optional scale_in scheduled action
      scale_in_recurrence  = "0 18 * * 1-5"
      scale_in_count       = 0 # Default for min_size, desired_capacity and max_size
      # Override using: scale_out_min_size, scale_out_desired_capacity, scale_out_max_size
    }
  }
```

#### Instance Termination

The Auto Scaling Group may be configured with a [lifecycle hook](https://docs.aws.amazon.com/autoscaling/ec2/userguide/lifecycle-hooks.html)
that executes a provided Lambda function when the runner is terminated to terminate additional instances that were spawned.

The use of the termination lifecycle can be toggled using the `runner_enable_asg_recreation` variable.

When using this feature, a `builds/` directory relative to the root module will persist that contains the packaged Lambda function.

### Access the Runner instance

A few option are provided to access the runner instance:

1. Access via the Session Manager (SSM) by setting `runner_worker.ssm_access` to `true`. The policy to allow access via SSM is not
   very restrictive.
2. By setting none of the above, no keys or extra policies will be attached to the instance. You can still configure you own
   policies by attaching them to `runner_role`.

### GitLab runner cache

By default the module creates a cache for the runner in S3. Old objects are automatically removed via a configurable life cycle
policy on the bucket.

Creation of the bucket can be disabled and managed outside this module. A good use case is for sharing the cache across multiple
runners. For this purpose the cache is implemented as a sub module. For more details see the
[cache module](https://github.com/cattle-ops/terraform-aws-gitlab-runner/tree/main/modules/cache). An example implementation of
this use case can be found in the [runner-public](https://github.com/cattle-ops/terraform-aws-gitlab-runner/tree/main/examples/runner-public)
example.

In case you enable the access logging for the S3 cache bucket, you have to add the following statement to your S3 logging bucket
policy.

```json
{
    "Sid": "Allow access logging",
    "Effect": "Allow",
    "Principal": {
        "Service": "logging.s3.amazonaws.com"
    },
    "Action": "s3:PutObject",
    "Resource": "<s3-arn>/*"
}
```

## Removing the module

As the module creates a number of resources during runtime (key pairs and spot instance requests), it needs a special
procedure to remove them.

1. Use the AWS Console to set the desired capacity of all auto-scaling groups to 0. To find the correct ones use the
   `var.environment` as search criteria. Setting the desired capacity to 0 prevents AWS from creating new instances
   which will in turn create new resources.
2. Kill all agent ec2 instances via AWS Console. This triggers a Lambda function in the background which removes
   all resources created during runtime of the EC2 instances.
3. Wait 3 minutes so the Lambda function has enough time to delete the key pairs and spot instance requests.
4. Run a `terraform destroy` or `terraform apply` (depends on your setup) to remove the module.

If you don't follow the above procedure key pairs and spot instance requests might survive the removal and might cause
additional costs. But I have never seen that. You should also be fine by executing step 4 only.

# Usage

Common pitfalls are documented in [pitfalls.md](pitfalls.md).

## Configuration

The examples are configured with defaults that should work in general. The examples are in general configured for the
region Ireland `eu-west-1`. The only parameter that needs to be provided is the name of a SSM parameter holding the Runner
registration token and the URL of your GitLab instance. The Runner token is created in GitLab during the Runner registration process.
Create a file `terraform.tfvars` and put the Runner registration token in the SSM parameter.

```hcl
preregistered_runner_token_ssm_parameter_name = "my-gitlab-runner-token-ssm-parameter-name"
gitlab_url   = "https://my.gitlab.instance/"
```

The base image used to host the GitLab Runner agent is the latest available Amazon Linux 2 HVM EBS AMI. In previous versions of
this module a hard coded list of AMIs per region was provided. This list has been replaced by a search filter to find the latest
AMI. Setting the filter to `amzn2-ami-hvm-2.0.20200207.1-x86_64-ebs` will allow you to version lock the target AMI if needed.

The Runner uses a token to register with GitLab. This token is stored in the AWS SSM parameter store. The token has to be created
manually in GitLab and stored in the SSM parameter store. All other registration methods are deprecated and will be removed in
v8.0.0.

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

### Scenario: Basic usage

Below is a basic examples of usages of the module if your GitLab instance version is >= 16.0.0.

```hcl
module "runner" {
  # https://registry.terraform.io/modules/cattle-ops/gitlab-runner/aws/
  source  = "cattle-ops/gitlab-runner/aws"

  aws_region  = "eu-west-1"
  environment = "spot-runners"

  vpc_id    = module.vpc.vpc_id
  subnet_id = element(module.vpc.private_subnets, 0)
   
  runner_instance = {
    name       = "docker-default"      
  }
   
  runner_gitlab = {
    url = "https://gitlab.com"
     
    preregistered_runner_token_ssm_parameter_name = "my-gitlab-runner-token-ssm-parameter-name"
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

    preregistered_runner_token_ssm_parameter_name = "my-gitlab-runner-token-ssm-parameter-name"
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

    preregistered_runner_token_ssm_parameter_name = "my-gitlab-runner-token-ssm-parameter-name"
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

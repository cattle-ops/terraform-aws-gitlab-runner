variable "aws_region" {
  description = "AWS region."
  type        = string
}

variable "arn_format" {
  type        = string
  default     = "arn:aws"
  description = "ARN format to be used. May be changed to support deployment in GovCloud/China regions."
}

variable "environment" {
  description = "A name that identifies the environment, used as prefix and for tagging."
  type        = string
}

variable "vpc_id" {
  description = "The target VPC for the docker-machine and runner instances."
  type        = string
}

variable "subnet_id" {
  description = "Subnet id used for the runner and executors. Must belong to the VPC specified above."
  type        = string
  default     = "" # TODO remove as soon as subnet_id_runners and subnet_ids_gitlab_runner are gone. Variable is mandatory now.
}

variable "extra_security_group_ids_runner_agent" {
  description = "Optional IDs of extra security groups to apply to the runner agent. This will not apply to the runners spun up when using the docker+machine executor, which is the default."
  type        = list(string)
  default     = []
}

variable "metrics_autoscaling" {
  description = "A list of metrics to collect. The allowed values are GroupDesiredCapacity, GroupInServiceCapacity, GroupPendingCapacity, GroupMinSize, GroupMaxSize, GroupInServiceInstances, GroupPendingInstances, GroupStandbyInstances, GroupStandbyCapacity, GroupTerminatingCapacity, GroupTerminatingInstances, GroupTotalCapacity, GroupTotalInstances."
  type        = list(string)
  default     = null
}

variable "instance_type" {
  description = "Instance type used for the GitLab runner."
  type        = string
  default     = "t3.micro"
}

variable "runner_instance_ebs_optimized" {
  description = "Enable the GitLab runner instance to be EBS-optimized."
  type        = bool
  default     = true
}

variable "runner_instance_enable_monitoring" {
  description = "Enable the GitLab runner instance to have detailed monitoring."
  type        = bool
  default     = true
}

variable "runner_instance_spot_price" {
  description = "By setting a spot price bid price the runner agent will be created via a spot request. Be aware that spot instances can be stopped by AWS. Choose \"on-demand-price\" to pay up to the current on demand price for the instance type chosen."
  type        = string
  default     = null
}

variable "runner_instance_metadata_options_http_endpoint" {
  description = "Enable the Gitlab runner agent instance metadata service. The allowed values are enabled, disabled."
  type        = string
  default     = "enabled"
}

variable "runner_instance_metadata_options_http_tokens" {
  description = "Set if Gitlab runner agent instance metadata service session tokens are required. The allowed values are optional, required."
  type        = string
  default     = "optional"
}

variable "docker_machine_instance_type" {
  description = "Instance type used for the instances hosting docker-machine."
  type        = string
  default     = "m5.large"
}

variable "docker_machine_spot_price_bid" {
  description = "Spot price bid. The maximum price willing to pay. By default the price is limited by the current on demand price for the instance type chosen."
  type        = string
  default     = "on-demand-price"
}

variable "docker_machine_download_url" {
  description = "(Optional) By default the module will use `docker_machine_version` to download the GitLab mantained version of Docker Machien. Alternative you can set this property to download location of the distribution of for the OS. See also https://docs.gitlab.com/runner/executors/docker_machine.html#install"
  type        = string
  default     = ""
}

variable "docker_machine_version" {
  description = "By default docker_machine_download_url is used to set the docker machine version. Version of docker-machine. The version will be ingored once `docker_machine_download_url` is set."
  type        = string
  default     = "0.16.2-gitlab.12"
}

variable "runners_name" {
  description = "Name of the runner, will be used in the runner config.toml."
  type        = string
}

variable "runners_executor" {
  description = "The executor to use. Currently supports `docker+machine` or `docker`."
  type        = string
  default     = "docker+machine"
}

variable "runners_install_amazon_ecr_credential_helper" {
  description = "Install amazon-ecr-credential-helper inside `userdata_pre_install` script"
  type        = bool
  default     = false
}

variable "runners_gitlab_url" {
  description = "URL of the GitLab instance to connect to."
  type        = string
}

variable "runners_token" {
  description = "Token for the runner, will be used in the runner config.toml."
  type        = string
  default     = "__REPLACED_BY_USER_DATA__"
}

variable "runners_limit" {
  description = "Limit for the runners, will be used in the runner config.toml."
  type        = number
  default     = 0
}

variable "runners_concurrent" {
  description = "Concurrent value for the runners, will be used in the runner config.toml."
  type        = number
  default     = 10
}

variable "runners_idle_time" {
  description = "Idle time of the runners, will be used in the runner config.toml."
  type        = number
  default     = 600
}

variable "runners_idle_count" {
  description = "Idle count of the runners, will be used in the runner config.toml."
  type        = number
  default     = 0
}

variable "runners_max_builds" {
  description = "Max builds for each runner after which it will be removed, will be used in the runner config.toml. By default set to 0, no maxBuilds will be set in the configuration."
  type        = number
  default     = 0
}

variable "runners_image" {
  description = "Image to run builds, will be used in the runner config.toml"
  type        = string
  default     = "docker:18.03.1-ce"
}

variable "runners_privileged" {
  description = "Runners will run in privileged mode, will be used in the runner config.toml"
  type        = bool
  default     = true
}

variable "runners_disable_cache" {
  description = "Runners will not use local cache, will be used in the runner config.toml"
  type        = bool
  default     = false
}

variable "runners_add_dind_volumes" {
  description = "Add certificates and docker.sock to the volumes to support docker-in-docker (dind)"
  type        = bool
  default     = false
}

variable "runners_additional_volumes" {
  description = "Additional volumes that will be used in the runner config.toml, e.g Docker socket"
  type        = list(any)
  default     = []
}

variable "runners_shm_size" {
  description = "shm_size for the runners, will be used in the runner config.toml"
  type        = number
  default     = 0
}

variable "runners_docker_runtime" {
  description = "docker runtime for runners, will be used in the runner config.toml"
  type        = string
  default     = ""
}

variable "runners_helper_image" {
  description = "Overrides the default helper image used to clone repos and upload artifacts, will be used in the runner config.toml"
  type        = string
  default     = ""
}

variable "runners_pull_policy" {
  description = "pull_policy for the runners, will be used in the runner config.toml"
  type        = string
  default     = "always"
}

variable "runners_monitoring" {
  description = "Enable detailed cloudwatch monitoring for spot instances."
  type        = bool
  default     = false
}

variable "runners_ebs_optimized" {
  description = "Enable runners to be EBS-optimized."
  type        = bool
  default     = true
}

variable "runners_machine_autoscaling" {
  description = "Set autoscaling parameters based on periods, see https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runnersmachine-section"
  type = list(object({
    periods    = list(string)
    idle_count = number
    idle_time  = number
    timezone   = string
  }))
  default = []
}

variable "runners_root_size" {
  description = "Runner instance root size in GB."
  type        = number
  default     = 16
}

variable "runners_iam_instance_profile_name" {
  description = "IAM instance profile name of the runners, will be used in the runner config.toml"
  type        = string
  default     = ""
}

variable "runners_docker_registry_mirror" {
  description = "The docker registry mirror to use to avoid rate limiting by hub.docker.com"
  type        = string
  default     = ""
}

variable "runners_environment_vars" {
  description = "Environment variables during build execution, e.g. KEY=Value, see runner-public example. Will be used in the runner config.toml"
  type        = list(string)
  default     = []
}

variable "runners_pre_build_script" {
  description = "Script to execute in the pipeline just before the build, will be used in the runner config.toml"
  type        = string
  default     = "\"\""
}

variable "runners_post_build_script" {
  description = "Commands to be executed on the Runner just after executing the build, but before executing after_script. "
  type        = string
  default     = "\"\""
}

variable "runners_pre_clone_script" {
  description = "Commands to be executed on the Runner before cloning the Git repository. this can be used to adjust the Git client configuration first, for example. "
  type        = string
  default     = "\"\""
}

variable "runners_request_concurrency" {
  description = "Limit number of concurrent requests for new jobs from GitLab (default 1)"
  type        = number
  default     = 1
}

variable "runners_output_limit" {
  description = "Sets the maximum build log size in kilobytes, by default set to 4096 (4MB)"
  type        = number
  default     = 4096
}

variable "userdata_pre_install" {
  description = "User-data script snippet to insert before GitLab runner install"
  type        = string
  default     = ""
}

variable "userdata_post_install" {
  description = "User-data script snippet to insert after GitLab runner install"
  type        = string
  default     = ""
}

variable "runners_use_private_address" {
  description = "Restrict runners to the use of a private IP address. If `runner_agent_uses_private_address` is set to `true`(default), `runners_use_private_address` will also apply for the agent."
  type        = bool
  default     = true
}

variable "runner_agent_uses_private_address" {
  description = "Restrict the runner agent to the use of a private IP address. If `runner_agent_uses_private_address` is set to `false` it will override the `runners_use_private_address` for the agent."
  type        = bool
  default     = true
}

variable "runners_request_spot_instance" {
  description = "Whether or not to request spot instances via docker-machine"
  type        = bool
  default     = true
}

variable "runners_check_interval" {
  description = "defines the interval length, in seconds, between new jobs check."
  type        = number
  default     = 3
}

variable "cache_bucket_prefix" {
  description = "Prefix for s3 cache bucket name."
  type        = string
  default     = ""
}

variable "cache_bucket_name_include_account_id" {
  description = "Boolean to add current account ID to cache bucket name."
  type        = bool
  default     = true
}

variable "cache_bucket_set_random_suffix" {
  description = "Append the cache bucket name with a random string suffix"
  type        = bool
  default     = false
}

variable "cache_bucket_versioning" {
  description = "Boolean used to enable versioning on the cache bucket, false by default."
  type        = bool
  default     = false
}

variable "cache_expiration_days" {
  description = "Number of days before cache objects expires."
  type        = number
  default     = 1
}

variable "cache_shared" {
  description = "Enables cache sharing between runners, false by default."
  type        = bool
  default     = false
}

variable "gitlab_runner_version" {
  description = "Version of the [GitLab runner](https://gitlab.com/gitlab-org/gitlab-runner/-/releases)."
  type        = string
  default     = "14.8.2"
}

variable "enable_ping" {
  description = "Allow ICMP Ping to the ec2 instances."
  type        = bool
  default     = false
}

variable "gitlab_runner_egress_rules" {
  description = "List of egress rules for the gitlab runner instance."
  type = list(object({
    cidr_blocks      = list(string)
    ipv6_cidr_blocks = list(string)
    prefix_list_ids  = list(string)
    from_port        = number
    protocol         = string
    security_groups  = list(string)
    self             = bool
    to_port          = number
    description      = string
  }))
  default = [{
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    prefix_list_ids  = null
    from_port        = 0
    protocol         = "-1"
    security_groups  = null
    self             = null
    to_port          = 0
    description      = null
  }]
}

variable "gitlab_runner_security_group_ids" {
  description = "A list of security group ids that are allowed to access the gitlab runner agent"
  type        = list(string)
  default     = []
}

variable "gitlab_runner_security_group_description" {
  description = "A description for the gitlab-runner security group"
  type        = string
  default     = "A security group containing gitlab-runner agent instances"
}

variable "enable_cloudwatch_logging" {
  description = "Boolean used to enable or disable the CloudWatch logging."
  type        = bool
  default     = true
}

variable "cloudwatch_logging_retention_in_days" {
  description = "Retention for cloudwatch logs. Defaults to unlimited"
  type        = number
  default     = 0
}

variable "tags" {
  description = "Map of tags that will be added to created resources. By default resources will be tagged with name and environment."
  type        = map(string)
  default     = {}
}

variable "agent_tags" {
  description = "Map of tags that will be added to agent EC2 instances."
  type        = map(string)
  default     = {}
}

variable "runner_tags" {
  description = "Map of tags that will be added to runner EC2 instances."
  type        = map(string)
  default     = {}
}

variable "role_tags" {
  description = "Map of tags that will be added to the role created. Useful for tag based authorization."
  type        = map(string)
  default     = {}
}

variable "allow_iam_service_linked_role_creation" {
  description = "Boolean used to control attaching the policy to a runner instance to create service linked roles."
  type        = bool
  default     = true
}

variable "docker_machine_options" {
  description = "List of additional options for the docker machine config. Each element of this list must be a key=value pair. E.g. '[\"amazonec2-zone=a\"]'"
  type        = list(string)
  default     = []
}

variable "instance_role_json" {
  description = "Default runner instance override policy, expected to be in JSON format."
  type        = string
  default     = ""
}

variable "docker_machine_role_json" {
  description = "Docker machine runner instance override policy, expected to be in JSON format."
  type        = string
  default     = ""
}

variable "docker_machine_security_group_description" {
  description = "A description for the docker-machine security group"
  type        = string
  default     = "A security group containing docker-machine instances"
}

variable "ami_filter" {
  description = "List of maps used to create the AMI filter for the Gitlab runner agent AMI. Must resolve to an Amazon Linux 1 or 2 image."
  type        = map(list(string))

  default = {
    name = ["amzn2-ami-hvm-2.*-x86_64-ebs"]
  }
}

variable "ami_owners" {
  description = "The list of owners used to select the AMI of Gitlab runner agent instances."
  type        = list(string)
  default     = ["amazon"]
}

variable "runner_ami_filter" {
  description = "List of maps used to create the AMI filter for the Gitlab runner docker-machine AMI."
  type        = map(list(string))

  default = {
    name = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

variable "runner_ami_owners" {
  description = "The list of owners used to select the AMI of Gitlab runner docker-machine instances."
  type        = list(string)

  # Canonical
  default = ["099720109477"]
}

variable "gitlab_runner_registration_config" {
  description = "Configuration used to register the runner. See the README for an example, or reference the examples in the examples directory of this repo."
  type        = map(string)

  default = {
    registration_token = ""
    tag_list           = ""
    description        = ""
    locked_to_project  = ""
    run_untagged       = ""
    maximum_timeout    = ""
    access_level       = ""
  }
}

variable "secure_parameter_store_runner_token_key" {
  description = "The key name used store the Gitlab runner token in Secure Parameter Store"
  type        = string
  default     = "runner-token"
}

variable "secure_parameter_store_runner_sentry_dsn" {
  description = "The Sentry DSN name used to store the Sentry DSN in Secure Parameter Store"
  type        = string
  default     = "sentry-dsn"
}

variable "enable_manage_gitlab_token" {
  description = "Boolean to enable the management of the GitLab token in SSM. If `true` the token will be stored in SSM, which means the SSM property is a terraform managed resource. If `false` the Gitlab token will be stored in the SSM by the user-data script during creation of the the instance. However the SSM parameter is not managed by terraform and will remain in SSM after a `terraform destroy`."
  type        = bool
  default     = true
}

variable "overrides" {
  description = <<-EOT
    This map provides the possibility to override some defaults. 
    The following attributes are supported: 
      * `name_sg` set the name prefix and overwrite the `Name` tag for all security groups created by this module. 
      * `name_runner_agent_instance` set the name prefix and override the `Name` tag for the EC2 gitlab runner instances defined in the auto launch configuration. 
      * `name_docker_machine_runners` override the `Name` tag of EC2 instances created by the runner agent. 
      * `name_iam_objects` set the name prefix of all AWS IAM resources created by this module.
  EOT
  type        = map(string)

  default = {
    name_sg                     = ""
    name_iam_objects            = ""
    name_runner_agent_instance  = ""
    name_docker_machine_runners = ""
  }
}

variable "cache_bucket" {
  description = "Configuration to control the creation of the cache bucket. By default the bucket will be created and used as shared cache. To use the same cache across multiple runners disable the creation of the cache and provide a policy and bucket name. See the public runner example for more details."
  type        = map(any)

  default = {
    create = true
    policy = ""
    bucket = ""
  }
}

variable "enable_runner_user_data_trace_log" {
  description = "Enable bash xtrace for the user data script that creates the EC2 instance for the runner agent. Be aware this could log sensitive data such as you GitLab runner token."
  type        = bool
  default     = false
}

variable "enable_schedule" {
  description = "Flag used to enable/disable auto scaling group schedule for the runner instance. "
  type        = bool
  default     = false
}

variable "schedule_config" {
  description = "Map containing the configuration of the ASG scale-in and scale-up for the runner instance. Will only be used if enable_schedule is set to true. "
  type        = map(any)
  default = {
    scale_in_recurrence  = "0 18 * * 1-5"
    scale_in_count       = 0
    scale_out_recurrence = "0 8 * * 1-5"
    scale_out_count      = 1
  }
}

variable "runner_root_block_device" {
  description = "The EC2 instance root block device configuration. Takes the following keys: `device_name`, `delete_on_termination`, `volume_type`, `volume_size`, `encrypted`, `iops`, `throughput`, `kms_key_id`"
  type        = map(string)
  default     = {}
}

variable "enable_runner_ssm_access" {
  description = "Add IAM policies to the runner agent instance to connect via the Session Manager."
  type        = bool
  default     = false
}

variable "enable_docker_machine_ssm_access" {
  description = "Add IAM policies to the docker-machine instances to connect via the Session Manager."
  type        = bool
  default     = false
}

variable "runners_volumes_tmpfs" {
  type = list(object({
    volume  = string
    options = string
  }))
  default = []
}

variable "runners_services_volumes_tmpfs" {
  type = list(object({
    volume  = string
    options = string
  }))
  default = []
}

variable "kms_key_id" {
  description = "KMS key id to encrypted the CloudWatch logs. Ensure CloudWatch has access to the provided KMS key."
  type        = string
  default     = ""
}

variable "enable_kms" {
  description = "Let the module manage a KMS key, logs will be encrypted via KMS. Be-aware of the costs of an custom key."
  type        = bool
  default     = false
}

variable "kms_alias_name" {
  description = "Alias added to the kms_key (if created and not provided by kms_key_id)"
  type        = string
  default     = ""
}

variable "kms_deletion_window_in_days" {
  description = "Key rotation window, set to 0 for no rotation. Only used when `enable_kms` is set to `true`."
  type        = number
  default     = 7
}

variable "enable_eip" {
  description = "Enable the assignment of an EIP to the gitlab runner instance"
  default     = false
  type        = bool
}

variable "enable_asg_recreation" {
  description = "Enable automatic redeployment of the Runner ASG when the Launch Configs change."
  default     = true
  type        = bool
}

variable "asg_delete_timeout" {
  description = "Timeout when trying to delete the Runner ASG."
  default     = "10m"
  type        = string
}

variable "asg_max_instance_lifetime" {
  description = "The seconds before an instance is refreshed in the ASG."
  default     = null
  type        = number
}

variable "permissions_boundary" {
  description = "Name of permissions boundary policy to attach to AWS IAM roles"
  default     = ""
  type        = string
}

variable "log_group_name" {
  description = "Option to override the default name (`environment`) of the log group, requires `enable_cloudwatch_logging = true`."
  default     = null
  type        = string
}

variable "runner_iam_policy_arns" {
  type        = list(string)
  description = "List of policy ARNs to be added to the instance profile of the gitlab runner agent ec2 instance."
  default     = []
}

variable "docker_machine_iam_policy_arns" {
  type        = list(string)
  description = "List of policy ARNs to be added to the instance profile of the docker machine runners."
  default     = []
}

variable "sentry_dsn" {
  default     = "__SENTRY_DSN_REPLACED_BY_USER_DATA__"
  description = "Sentry DSN of the project for the runner to use (uses legacy DSN format)"
  type        = string
}

variable "docker_machine_egress_rules" {
  description = "List of egress rules for the docker-machine instance(s)."
  type = list(object({
    cidr_blocks      = list(string)
    ipv6_cidr_blocks = list(string)
    prefix_list_ids  = list(string)
    from_port        = number
    protocol         = string
    security_groups  = list(string)
    self             = bool
    to_port          = number
    description      = string
  }))
  default = [{
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    prefix_list_ids  = null
    from_port        = 0
    protocol         = "-1"
    security_groups  = null
    self             = null
    to_port          = 0
    description      = "Allow all egress traffic for docker machine build runners"
  }]
}

variable "subnet_id_runners" {
  description = "Deprecated! Use subnet_id instead. List of subnets used for hosting the gitlab-runners."
  type        = string
  default     = ""
}

variable "subnet_ids_gitlab_runner" {
  description = "Deprecated! Use subnet_id instead. Subnet used for hosting the GitLab runner."
  type        = list(string)
  default     = []
}

variable "asg_terminate_lifecycle_hook_name" {
  description = "Specifies a custom name for the ASG terminate lifecycle hook and related resources."
  type        = string
  default     = null
}

variable "asg_terminate_lifecycle_hook_create" {
  description = "Boolean toggling the creation of the ASG instance terminate lifecycle hook."
  type        = bool
  default     = true
}

variable "asg_terminate_lifecycle_hook_heartbeat_timeout" {
  description = "The amount of time, in seconds, for the instances to remain in wait state."
  type        = number
  default     = 90
}

variable "asg_terminate_lifecycle_lambda_memory_size" {
  description = "The memory size in MB to allocate to the terminate-instances Lambda function."
  type        = number
  default     = 128
}

variable "asg_terminate_lifecycle_lambda_timeout" {
  description = "Amount of time the terminate-instances Lambda Function has to run in seconds."
  default     = 30
  type        = number
}

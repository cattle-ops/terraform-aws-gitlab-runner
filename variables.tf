/*
 * Global variables
 */
variable "vpc_id" {
  description = "The target VPC for the agent and executors (e.g. docker-machine) instances."
  type        = string
}

variable "subnet_id" {
  description = "Subnet id used for the agent and executors. Must belong to the `vpc_id`."
  type        = string
}

variable "kms_key_id" {
  description = "KMS key id to encrypt the resources. Ensure CloudWatch and Agent/Executors have access to the provided KMS key."
  type        = string
  default     = ""
}

variable "enable_managed_kms_key" {
  description = "Let the module manage a KMS key. Be-aware of the costs of an custom key. Do not specify a `kms_key_id` when `enable_kms` is set to `true`."
  type        = bool
  default     = false
}

variable "kms_managed_alias_name" {
  description = "Alias added to the created KMS key."
  type        = string
  default     = ""
}

variable "kms_managed_deletion_rotation_window_in_days" {
  description = "Key deletion/rotation window for the created KMS key. Set to 0 for no rotation/deletion window."
  type        = number
  default     = 7
}

variable "iam_permissions_boundary" {
  description = "Name of permissions boundary policy to attach to AWS IAM roles"
  type        = string
  default     = ""
}

variable "environment" {
  description = "A name that identifies the environment, used as prefix and for tagging."
  type        = string
}

variable "tags" {
  description = "Map of tags that will be added to created resources. By default resources will be tagged with name and environment."
  type        = map(string)
  default     = {}
}

variable "suppressed_tags" {
  description = "List of tag keys which are removed from `tags`, `agent_tags`  and `executor_tags` and never added as default tag by the module."
  type        = list(string)
  default     = []
}

variable "security_group_prefix" {
  description = "Set the name prefix and overwrite the `Name` tag for all security groups."
  type        = string
  default     = ""
}

variable "iam_object_prefix" {
  description = "Set the name prefix of all AWS IAM resources."
  type        = string
  default     = ""
}

/*
 * Runner Manager: A type of runner that can create multiple runners for autoscaling. Specific to the type of executor used.
 */
variable "runner_manager_maximum_concurrent_jobs" {
  description = "The maximum number of jobs which can be processed by all executors at the same time."
  type        = number
  default     = 10
}

variable "runner_manager_sentry_dsn" {
  description = "Sentry DSN of the project for the Agent to use (uses legacy DSN format)"
  type        = string
  default     = "__SENTRY_DSN_REPLACED_BY_USER_DATA__"
}

variable "runner_manager_gitlab_check_interval" {
  description = "Number of seconds between checking for available jobs."
  type        = number
  default     = 3
}

variable "runner_manager_prometheus_listen_address" {
  description = "Defines an address (<host>:<port>) the Prometheus metrics HTTP server should listen on."
  type        = string
  default     = ""
}

/*
 * Runner: The agent that runs the code on the host platform and displays in the UI.
 */
variable "runner_instance" {
  description = <<-EOT
    additional_tags = Map of tags that will be added to the Agent instance.
    ebs_optimized = Enable EBS optimization for the Agent instance.
    name_prefix = Set the name prefix and override the `Name` tag for the Agent instance.
    root_device_config = The Agent's root block device configuration. Takes the following keys: `device_name`, `delete_on_termination`, `volume_type`, `volume_size`, `encrypted`, `iops`, `throughput`, `kms_key_id`
    spot_price = By setting a spot price bid price the runner agent will be created via a spot request. Be aware that spot instances can be stopped by AWS. Choose \"on-demand-price\" to pay up to the current on demand price for the instance type chosen.
    type = EC2 instance type used.
  EOT
  type = object({
    additional_tags = optional(map(string))
    ebs_optimized = optional(bool, true)
    name_prefix = optional(string)
    root_device_config = optional(map(string))
    spot_price = optional(string, null)
    type = string
  })
  default = {
    type = "t3.micro"
  }
}

variable "runner_ami_filter" {
  description = "List of maps used to create the AMI filter for the Agent AMI. Must resolve to an Amazon Linux 1 or 2 image."
  type        = map(list(string))

  default = {
    name = ["amzn2-ami-hvm-2.*-x86_64-ebs"]
  }
}

variable "runner_ami_owners" {
  description = "The list of owners used to select the AMI of the Agent instance."
  type        = list(string)
  default     = ["amazon"]
}

variable "runner_enable_monitoring" {
  description = "Enable the detailed monitoring on the Agent instance."
  type        = bool
  default     = true
}

variable "runner_collect_autoscaling_metrics" {
  description = "A list of metrics to collect. The allowed values are GroupDesiredCapacity, GroupInServiceCapacity, GroupPendingCapacity, GroupMinSize, GroupMaxSize, GroupInServiceInstances, GroupPendingInstances, GroupStandbyInstances, GroupStandbyCapacity, GroupTerminatingCapacity, GroupTerminatingInstances, GroupTotalCapacity, GroupTotalInstances."
  type        = list(string)
  default     = null
}

variable "runner_ping_enable" {
  description = "Allow ICMP Ping to the Agent. Specify `agent_ping_allowed_from_security_groups` too!"
  type        = bool
  default     = false
}

variable "runner_ping_allow_from_security_groups" {
  description = "A list of security group ids that are allowed to access the gitlab runner agent"
  type        = list(string)
  default     = []
}

variable "runner_security_group_description" {
  description = "A description for the Agents security group"
  type        = string
  default     = "A security group containing gitlab-runner agent instances"
}

variable "runner_extra_security_group_ids" {
  description = "IDs of security groups to add to the Agent."
  type        = list(string)
  default     = []
}

variable "runner_extra_egress_rules" {
  description = "List of egress rules for the Agent."
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
  default = [
    {
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = null
      from_port        = 0
      protocol         = "-1"
      security_groups  = null
      self             = null
      to_port          = 0
      description      = null
    }
  ]
}

variable "runner_role" {
    description = <<-EOT
        additional_tags = Map of tags that will be added to the role created. Useful for tag based authorization.
        allow_iam_service_linked_role_creation = Boolean used to control attaching the policy to the Agent to create service linked roles.
        assume_role_policy_json = The assume role policy for the Agent.
        create_role_profile = Whether to create the IAM role/profile for the Agent. If you provide your own role, make sure that it has the required permissions.
        policy_arns = List of policy ARNs to be added to the instance profile of the Agent.
        role_profile_name = IAM role/profile name for the Agent. If unspecified then `$${var.iam_object_prefix}-instance` is used.
    EOT
    type = object({
      additional_tags = optional(map(string))
      allow_iam_service_linked_role_creation = optional(bool, true)
      assume_role_policy_json = optional(string, "")
      create_role_profile = optional(bool, true)
      policy_arns = optional(list(string), [])
      role_profile_name = optional(string)
    })
    default = {}
}

variable "runner_enable_eip" {
  description = "Assigns an EIP to the Agent."
  type        = bool
  default     = false
}

variable "runner_use_private_address" {
  description = "Restrict the Agent to the use of a private IP address. If this is set to `false` it will override the `runners_use_private_address` for the agent."
  type        = bool
  default     = true
}

variable "runner_enable_ssm_access" {
  description = "Allows to connect to the Agent via SSM."
  type        = bool
  default     = false
}

variable "runner_metadata_options" {
  description = "Enable the Gitlab runner agent instance metadata service. IMDSv2 is enabled by default."
  type = object({
    http_endpoint               = string
    http_tokens                 = string
    http_put_response_hop_limit = number
    instance_metadata_tags      = string
  })
  default = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "disabled"
  }
}

variable "runner_schedule_enable" {
  description = "Set to `true` to enable the auto scaling group schedule for the Agent."
  type        = bool
  default     = false
}

variable "runner_max_instance_lifetime_seconds" {
  description = "The maximum time an Agent should live before it is killed."
  default     = null
  type        = number
}

variable "runner_enable_asg_recreation" {
  description = "Enable automatic redeployment of the Agent ASG when the Launch Configs change."
  default     = true
  type        = bool
}

variable "runner_schedule_config" {
  description = "Map containing the configuration of the ASG scale-out and scale-in for the Agent. Will only be used if `agent_schedule_enable` is set to `true`. "
  type        = map(any)
  default = {
    # Configure optional scale_out scheduled action
    scale_out_recurrence = "0 8 * * 1-5"
    scale_out_count      = 1 # Default for min_size, desired_capacity and max_size
    scale_out_time_zone  = "Etc/UTC"
    # Override using: scale_out_min_size, scale_out_desired_capacity, scale_out_max_size

    # Configure optional scale_in scheduled action
    scale_in_recurrence = "0 18 * * 1-5"
    scale_in_count      = 0 # Default for min_size, desired_capacity and max_size
    scale_in_time_zone  = "Etc/UTC"
    # Override using: scale_out_min_size, scale_out_desired_capacity, scale_out_max_size
  }
}

variable "runner_install_amazon_ecr_credential_helper" {
  description = "Install amazon-ecr-credential-helper inside `userdata_pre_install` script"
  type        = bool
  default     = false
}

variable "runner_docker_machine_version" {
  description = "By default docker_machine_download_url is used to set the docker machine version. This version will be ignored once `docker_machine_download_url` is set. The version number is maintained by the CKI project. Check out at https://gitlab.com/cki-project/docker-machine/-/releases"
  type        = string
  default     = "0.16.2-gitlab.19-cki.2"
}

variable "runner_docker_machine_download_url" {
  description = "(Optional) By default the module will use `docker_machine_version` to download the CKI maintained version (https://gitlab.com/cki-project/docker-machine) of Docker Machine. Alternative you can set this property to download location of the distribution of for the OS. See also https://docs.gitlab.com/runner/executors/docker_machine.html#install"
  type        = string
  default     = ""
}

variable "runner_yum_update" {
  description = "Run a `yum` update as part of starting the Agent"
  type        = bool
  default     = true
}

variable "runner_userdata_pre_install" {
  description = "User-data script snippet to insert before GitLab Runner install"
  type        = string
  default     = ""
}

variable "runner_userdata_post_install" {
  description = "User-data script snippet to insert after GitLab Runner install"
  type        = string
  default     = ""
}

variable "runner_user_data_extra" {
  description = "Extra commands to run as part of starting the Agent"
  type        = string
  default     = ""
}

variable "runner_user_data_enable_trace_log" {
  description = "Enable bash trace for the user data script on the Agent. Be aware this could log sensitive data such as you GitLab runner token."
  type        = bool
  default     = true
}

variable "runner_cloudwatch_enable" {
  description = "Boolean used to enable or disable the CloudWatch logging."
  type        = bool
  default     = true
}

variable "runner_cloudwatch_retention_days" {
  description = "Retention for cloudwatch logs. Defaults to unlimited. Requires `agent_cloudwatch_enable = true`."
  type        = number
  default     = 0
}

variable "runner_cloudwatch_log_group_name" {
  description = "Option to override the default name (`environment`) of the log group. Requires `agent_cloudwatch_enable = true`."
  default     = null
  type        = string
}

variable "runner_gitlab_runner_name" {
  description = "Name of the Gitlab Runner."
  type        = string
}

variable "runner_gitlab_runner_version" {
  description = "Version of the [GitLab runner](https://gitlab.com/gitlab-org/gitlab-runner/-/releases)."
  type        = string
  default     = "15.8.2"
}

variable "runner_gitlab_registration_config" {
  description = "Configuration used to register the Agent. See the README for an example, or reference the examples in the examples directory of this repo."
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

variable "runner_gitlab_token_secure_parameter_store" {
  description = "Name of the Secure Parameter Store entry to hold the GitLab Runner token."
  type        = string
  default     = "runner-token"
}

variable "runner_gitlab_ca_certificate" {
  description = "Trusted CA certificate bundle (PEM format). Example: `file(\"$${path.module}/ca.crt\")`"
  type        = string
  default     = ""
}

variable "runner_gitlab_certificate" {
  description = "Certificate of the GitLab instance to connect to (PEM format). Example: `file(\"$${path.module}/my-gitlab.crt\")`"
  type        = string
  default     = ""
}

variable "runner_gitlab_url" {
  description = "URL of the GitLab instance to connect to."
  type        = string
}

variable "runner_gitlab_clone_url" {
  description = "Overwrites the URL for the GitLab instance. Use only if the agent can’t connect to the GitLab URL."
  type        = string
  default     = ""
}

variable "runner_gitlab_token" {
  description = "Token for the Agent to connect to GitLab"
  type        = string
  default     = "__REPLACED_BY_USER_DATA__"
}

variable "runner_sentry_secure_parameter_store_name" {
  description = "The Sentry DSN name used to store the Sentry DSN in Secure Parameter Store"
  type        = string
  default     = "sentry-dsn"
}

variable "runner_terminate_ec2_lifecycle_hook_name" {
  description = "Specifies a custom name for the ASG terminate lifecycle hook and related resources."
  type        = string
  default     = null
}

variable "runner_terraform_timeout_delete_asg" {
  description = "Timeout when trying to delete the Agent ASG."
  default     = "10m"
  type        = string
}

/*
 * Runner Worker: The process created by the runner on the host computing platform to run jobs.
 */
variable "runner_worker_type" {
  description = "The executor type to use. Currently supports `docker+machine` or `docker`."
  type        = string
  default     = "docker+machine"

  validation {
    condition     = contains(["docker+machine", "docker"], var.runner_worker_type)
    error_message = "The executor currently supports `docker+machine` or `docker`."
  }
}

variable "runner_worker_enable_ssm_access" {
  description = "Allows to connect to the Executor via SSM."
  type        = bool
  default     = false
}

variable "runner_worker_max_jobs" {
  description = "Number of jobs which can be processed in parallel by the executor."
  type        = number
  default     = 0
}

variable "runner_worker_idle_time" {
  description = "Idle time of the runners before they are destroyed."
  type        = number
  default     = 600
}

variable "runner_worker_idle_count" {
  description = "Number of idle Executor instances."
  type        = number
  default     = 0
}

variable "runner_worker_request_concurrency" {
  description = "Limit number of concurrent requests for new jobs from GitLab (default 1)."
  type        = number
  default     = 1
}

variable "runner_worker_output_limit" {
  description = "Sets the maximum build log size in kilobytes, by default set to 4096 (4MB)."
  type        = number
  default     = 4096
}

variable "runner_worker_extra_environment_variables" {
  description = "Environment variables during build execution, e.g. KEY=Value, see runner-public example."
  type        = list(string)
  default     = []
}

variable "runner_worker_cache_shared" {
  description = "Enables cache sharing between runners. `false` by default."
  type        = bool
  default     = false
}

variable "runner_worker_cache_s3_bucket" {
  description = <<-EOT
    Configuration to control the creation of the cache bucket. By default the bucket will be created and used as shared
    cache. To use the same cache across multiple runners disable the creation of the cache and provide a policy and
    bucket name. See the public runner example for more details."
  EOT
  type        = map(any)
  default = {
    create = true
    policy = ""
    bucket = ""
  }
}

variable "runner_worker_cache_s3_authentication_type" {
  description = "A string that declares the AuthenticationType for [runners.cache.s3]. Can either be 'iam' or 'credentials'"
  type        = string
  default     = "iam"
}

variable "runner_worker_cache_s3_expiration_days" {
  description = "Number of days before cache objects expire."
  type        = number
  default     = 1
}

variable "runner_worker_cache_s3_enable_versioning" {
  description = "Boolean used to enable versioning on the cache bucket, false by default."
  type        = bool
  default     = false
}

variable "runner_worker_cache_s3_bucket_prefix" {
  description = "Prefix for s3 cache bucket name."
  type        = string
  default     = ""
}

variable "runner_worker_cache_s3_bucket_name_include_account_id" {
  description = "Boolean to add current account ID to cache bucket name."
  type        = bool
  default     = true
}

variable "runner_worker_cache_s3_bucket_enable_random_suffix" {
  description = "Append the cache bucket name with a random string suffix"
  type        = bool
  default     = false
}

variable "runner_worker_cache_s3_logging_bucket_id" {
  type        = string
  description = "S3 Bucket ID where the access logs to the cache bucket are stored."
  default     = null
}

variable "runner_worker_cache_s3_logging_bucket_prefix" {
  type        = string
  description = "Prefix within the `executor_cache_logging_bucket_name`."
  default     = null
}

variable "runner_worker_pre_clone_script" {
  description = "Script to execute in the pipeline before cloning the Git repository. this can be used to adjust the Git client configuration first, for example."
  type        = string
  default     = "\"\""
}

variable "runner_worker_pre_build_script" {
  description = "Script to execute in the pipeline just before the build."
  type        = string
  default     = "\"\""
}

variable "runner_worker_post_build_script" {
  description = "Script to execute in the pipeline just after the build, but before executing after_script."
  type        = string
  default     = "\"\""
}

/*
 * Docker Executor variables.
 */
variable "runner_worker_docker_volumes_tmpfs" {
  description = "Mount a tmpfs in Executor container. https://docs.gitlab.com/runner/executors/docker.html#mounting-a-directory-in-ram"
  type = list(object({
    volume  = string
    options = string
  }))
  default = []
}

variable "runner_worker_docker_services" {
  description = "Starts additional services with the Docker container. All fields must be set (examine the Dockerfile of the service image for the entrypoint - see ./examples/runner-default/main.tf)"
  type = list(object({
    name       = string
    alias      = string
    entrypoint = list(string)
    command    = list(string)
  }))
  default = []
}

variable "runner_worker_docker_services_volumes_tmpfs" {
  description = "Mount a tmpfs in gitlab service container. https://docs.gitlab.com/runner/executors/docker.html#mounting-a-directory-in-ram"
  type = list(object({
    volume  = string
    options = string
  }))
  default = []
}

variable "runner_worker_docker_add_dind_volumes" {
  description = "Add certificates and docker.sock to the volumes to support docker-in-docker (dind)"
  type        = bool
  default     = false
}

variable "runner_worker_docker_options" {
  description = <<EOT
    Options added to the [runners.docker] section of config.toml to configure the Docker container of the Executors. For
    details check https://docs.gitlab.com/runner/configuration/advanced-configuration.html

    Default values if the option is not given:
      disable_cache = "false"
      image         = "docker:18.03.1-ce"
      privileged    = "true"
      pull_policy   = "always"
      shm_size      = 0
      tls_verify    = "false"
      volumes       = "/cache"
  EOT

  type = object({
    allowed_images               = optional(list(string))
    allowed_pull_policies        = optional(list(string))
    allowed_services             = optional(list(string))
    cache_dir                    = optional(string)
    cap_add                      = optional(list(string))
    cap_drop                     = optional(list(string))
    container_labels             = optional(list(string))
    cpuset_cpus                  = optional(string)
    cpu_shares                   = optional(number)
    cpus                         = optional(string)
    devices                      = optional(list(string))
    device_cgroup_rules          = optional(list(string))
    disable_cache                = optional(bool, false)
    disable_entrypoint_overwrite = optional(bool)
    dns                          = optional(list(string))
    dns_search                   = optional(list(string))
    extra_hosts                  = optional(list(string))
    gpus                         = optional(string)
    helper_image                 = optional(string)
    helper_image_flavor          = optional(string)
    host                         = optional(string)
    hostname                     = optional(string)
    image                        = optional(string, "docker:18.03.1-ce")
    isolation                    = optional(string)
    links                        = optional(list(string))
    mac_address                  = optional(string)
    memory                       = optional(string)
    memory_swap                  = optional(string)
    memory_reservation           = optional(string)
    network_mode                 = optional(string)
    oom_kill_disable             = optional(bool)
    oom_score_adjust             = optional(number)
    privileged                   = optional(bool, true)
    pull_policies                = optional(list(string), ["always"])
    runtime                      = optional(string)
    security_opt                 = optional(list(string))
    shm_size                     = optional(number, 0)
    sysctls                      = optional(list(string))
    tls_cert_path                = optional(string)
    tls_verify                   = optional(bool, false)
    user                         = optional(string)
    userns_mode                  = optional(string)
    volumes                      = optional(list(string), ["/cache"])
    volumes_from                 = optional(list(string))
    volume_driver                = optional(string)
    wait_for_services_timeout    = optional(number)
  })

  default = {
    disable_cache = "false"
    image         = "docker:18.03.1-ce"
    privileged    = "true"
    pull_policy   = "always"
    shm_size      = 0
    tls_verify    = "false"
    volumes       = ["/cache"]
  }
}

/*
 * docker+machine Executor variables. The executor is the actual machine that runs the job. Please specify the
 * `executor_docker_*` variables as well as Docker is used on the docker+machine executor.
 */
variable "runner_worker_docker_machine_instance_type" {
  description = "Instance type used for the instances hosting docker-machine."
  type        = string
  default     = "m5.large"
}

variable "runner_worker_docker_machine_extra_role_tags" {
  description = "Map of tags that will be added to runner EC2 instances."
  type        = map(string)
  default     = {}
}

variable "runner_worker_docker_machine_extra_egress_rules" {
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
  default = [
    {
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = null
      from_port        = 0
      protocol         = "-1"
      security_groups  = null
      self             = null
      to_port          = 0
      description      = "Allow all egress traffic for docker machine build runners"
    }
  ]
}

variable "runner_worker_docker_machine_iam_instance_profile_name" {
  description = "IAM instance profile name of the Executors."
  type        = string
  default     = ""
}

variable "runner_worker_docker_machine_assume_role_json" {
  description = "Assume role policy for the docker+machine Executor."
  type        = string
  default     = ""
}

# executor
variable "runner_worker_docker_machine_extra_iam_policy_arns" {
  type        = list(string)
  description = "List of policy ARNs to be added to the instance profile of the docker+machine Executor."
  default     = []
}

variable "runner_worker_docker_machine_security_group_description" {
  description = "A description for the docker+machine Executor security group"
  type        = string
  default     = "A security group containing docker-machine instances"
}

variable "runner_worker_docker_machine_ami_filter" {
  description = "List of maps used to create the AMI filter for the docker+machine Executor."
  type        = map(list(string))

  default = {
    name = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

variable "runner_worker_docker_machine_ami_owners" {
  description = "The list of owners used to select the AMI of the docker+machine Executor."
  type        = list(string)

  # Canonical
  default = ["099720109477"]
}

variable "runner_worker_docker_machine_use_private_address" {
  description = "Restrict Executors to the use of a private IP address. If `agent_use_private_address` is set to `true` (default), `executor_docker_machine_use_private_address` will also apply for the agent."
  type        = bool
  default     = true
}

variable "runner_worker_docker_machine_instance_prefix" {
  description = "Set the name prefix and override the `Name` tag for the GitLab Runner Executor instances."
  type        = string
  default     = ""

  validation {
    condition     = length(var.runner_worker_docker_machine_instance_prefix) <= 28
    error_message = "Maximum length for docker+machine executor name is 28 characters!"
  }

  validation {
    condition     = var.runner_worker_docker_machine_instance_prefix == "" || can(regex("^[a-zA-Z0-9\\.-]+$", var.runner_worker_docker_machine_instance_prefix))
    error_message = "Valid characters for the docker+machine executor name are: [a-zA-Z0-9\\.-]."
  }
}

variable "runner_worker_docker_machine_enable_monitoring" {
  description = "Enable detailed cloudwatch monitoring for spot instances."
  type        = bool
  default     = false
}

variable "runner_worker_docker_machine_request_spot_instances" {
  description = "Whether or not to request spot instances via docker-machine"
  type        = bool
  default     = true
}

variable "runner_worker_docker_machine_userdata" {
  description = "Cloud-init user data that will be passed to the Executor EC2 instance. Should not be base64 encrypted."
  type        = string
  default     = ""
}

variable "runner_worker_docker_machine_ec2_volume_type" {
  description = "Executor volume type"
  type        = string
  default     = "gp2"
}

variable "runner_worker_docker_machine_ec2_root_size" {
  description = "Executor root size in GB."
  type        = number
  default     = 16
}

variable "runner_worker_docker_machine_ec2_ebs_optimized" {
  description = "Enable Executors to be EBS-optimized."
  type        = bool
  default     = true
}

variable "runner_worker_docker_machine_ec2_spot_price_bid" {
  description = "Spot price bid. The maximum price willing to pay. By default the price is limited by the current on demand price for the instance type chosen."
  type        = string
  default     = "on-demand-price"
}

variable "runner_worker_docker_machine_ec2_options" {
  # cspell:ignore amazonec
  description = "List of additional options for the docker+machine config. Each element of this list must be a key=value pair. E.g. '[\"amazonec2-zone=a\"]'"
  type        = list(string)
  default     = []
}

variable "runner_worker_docker_machine_ec2_metadata_options" {
  description = "Enable the docker machine instances metadata service. Requires you use GitLab maintained docker machines."
  type = object({
    http_tokens                 = string
    http_put_response_hop_limit = number
  })
  default = {
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }
}

variable "runner_worker_docker_machine_autoscaling_options" {
  description = "Set autoscaling parameters based on periods, see https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runnersmachine-section"
  type = list(object({
    periods           = list(string)
    idle_count        = optional(number)
    idle_scale_factor = optional(number)
    idle_count_min    = optional(number)
    idle_time         = optional(number)
    timezone          = optional(string, "UTC")
  }))
  default = []

}

variable "runner_worker_docker_machine_max_builds" {
  description = "Destroys the executor after processing this many jobs. Set to `0` to disable this feature."
  type        = number
  default     = 0
}

variable "runner_worker_docker_machine_docker_registry_mirror_url" {
  description = "The docker registry mirror to use to avoid rate limiting by hub.docker.com"
  type        = string
  default     = ""
}

variable "show_user_data_in_plan" {
  description = "When enabled, shows the diff for agent configuration files in Terraform plan: `config.toml` and user data script"
  type        = bool
  default     = false
}

/*
 * Global variables
 */
variable "vpc_id" {
  description = "The VPC used for the runner and runner workers."
  type        = string
}

variable "subnet_id" {
  description = <<-EOT
    Subnet id used for the Runner and Runner Workers. Must belong to the `vpc_id`. In case the fleet mode is used, multiple subnets for
    the Runner Workers can be provided with runner_worker_docker_machine_instance.subnet_ids.
  EOT
  type        = string
}

variable "kms_key_id" {
  description = "KMS key id to encrypt the resources. Ensure that CloudWatch and Runner/Runner Workers have access to the provided KMS key."
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
  description = "List of tag keys which are automatically removed and never added as default tag by the module."
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
 * Runner Manager: A manager which creates multiple Runners (only one Runner supported by this module) which in turn creates
 *                 multiple Runner Workers (e.g. docker-machine).
 */
variable "runner_manager" {
  description = <<-EOT
    For details check https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-global-section

    gitlab_check_interval = Number of seconds between checking for available jobs (check_interval)
    maximum_concurrent_jobs = The maximum number of jobs which can be processed by all Runners at the same time (concurrent).
    prometheus_listen_address = Defines an address (<host>:<port>) the Prometheus metrics HTTP server should listen on (listen_address).
    sentry_dsn = Sentry DSN of the project for the Runner Manager to use (uses legacy DSN format) (sentry_dsn)
  EOT
  type = object({
    gitlab_check_interval     = optional(number, 3)
    maximum_concurrent_jobs   = optional(number, 10)
    prometheus_listen_address = optional(string, "")
    sentry_dsn                = optional(string, "__SENTRY_DSN_REPLACED_BY_USER_DATA__")
  })
  default = {}
}

/*
 * Runner: The agent that runs the code on the host platform and displays in the UI.
 */
variable "runner_instance" {
  description = <<-EOT
    additional_tags = Map of tags that will be added to the Runner instance.
    collect_autoscaling_metrics = A list of metrics to collect. The allowed values are GroupDesiredCapacity, GroupInServiceCapacity, GroupPendingCapacity, GroupMinSize, GroupMaxSize, GroupInServiceInstances, GroupPendingInstances, GroupStandbyInstances, GroupStandbyCapacity, GroupTerminatingCapacity, GroupTerminatingInstances, GroupTotalCapacity, GroupTotalInstances.
    ebs_optimized = Enable EBS optimization for the Runner instance.
    max_lifetime_seconds = The maximum time a Runner should live before it is killed.
    monitoring = Enable the detailed monitoring on the Runner instance.
    name = Name of the Runner instance.
    name_prefix = Set the name prefix and override the `Name` tag for the Runner instance.
    private_address_only = Restrict the Runner to use private IP addresses only. If this is set to `true` the Runner will use a private IP address only in case the Runner Workers use private addresses only.
    root_device_config = The Runner's root block device configuration. Takes the following keys: `device_name`, `delete_on_termination`, `volume_type`, `volume_size`, `encrypted`, `iops`, `throughput`, `kms_key_id`
    spot_price = By setting a spot price bid price the Runner is created via a spot request. Be aware that spot instances can be stopped by AWS. Choose \"on-demand-price\" to pay up to the current on demand price for the instance type chosen.
    ssm_access = Allows to connect to the Runner via SSM.
    type = EC2 instance type used.
    use_eip = Assigns an EIP to the Runner.
  EOT
  type = object({
    additional_tags             = optional(map(string))
    collect_autoscaling_metrics = optional(list(string), null)
    ebs_optimized               = optional(bool, true)
    max_lifetime_seconds        = optional(number, null)
    monitoring                  = optional(bool, true)
    name                        = string
    name_prefix                 = optional(string)
    private_address_only        = optional(bool, true)
    root_device_config          = optional(map(string), {})
    spot_price                  = optional(string, null)
    ssm_access                  = optional(bool, false)
    type                        = optional(string, "t3.micro")
    use_eip                     = optional(bool, false)
  })
  default = {
    name = "gitlab-runner"
  }
}

variable "runner_ami_filter" {
  description = "List of maps used to create the AMI filter for the Runner AMI. Must resolve to an Amazon Linux 1 or 2 image."
  type        = map(list(string))

  default = {
    name = ["amzn2-ami-hvm-2.*-x86_64-ebs"]
  }
}

variable "runner_ami_owners" {
  description = "The list of owners used to select the AMI of the Runner instance."
  type        = list(string)
  default     = ["amazon"]
}

variable "runner_networking" {
  description = <<-EOT
    allow_incoming_ping = Allow ICMP Ping to the Runner. Specify `allow_incoming_ping_security_group_ids` too!
    allow_incoming_ping_security_group_ids = A list of security group ids that are allowed to ping the Runner.
    security_group_description = A description for the Runner's security group
    security_group_ids = IDs of security groups to add to the Runner.
  EOT
  type = object({
    allow_incoming_ping                    = optional(bool, false)
    allow_incoming_ping_security_group_ids = optional(list(string), [])
    security_group_description             = optional(string, "A security group containing gitlab-runner agent instances")
    security_group_ids                     = optional(list(string), [])
  })
  default = {}
}

variable "runner_networking_egress_rules" {
  description = "List of egress rules for the Runner."
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
        allow_iam_service_linked_role_creation = Boolean used to control attaching the policy to the Runner to create service linked roles.
        assume_role_policy_json = The assume role policy for the Runner.
        create_role_profile = Whether to create the IAM role/profile for the Runner. If you provide your own role, make sure that it has the required permissions.
        policy_arns = List of policy ARNs to be added to the instance profile of the Runner.
        role_profile_name = IAM role/profile name for the Runner. If unspecified then `$${var.iam_object_prefix}-instance` is used.
    EOT
  type = object({
    additional_tags                        = optional(map(string))
    allow_iam_service_linked_role_creation = optional(bool, true)
    assume_role_policy_json                = optional(string, "")
    create_role_profile                    = optional(bool, true)
    policy_arns                            = optional(list(string), [])
    role_profile_name                      = optional(string)
  })
  default = {}
}

variable "runner_metadata_options" {
  description = "Enable the Runner instance metadata service. IMDSv2 is enabled by default."
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
  description = "Set to `true` to enable the auto scaling group schedule for the Runner."
  type        = bool
  default     = false
}


variable "runner_enable_asg_recreation" {
  description = "Enable automatic redeployment of the Runner's ASG when the Launch Configs change."
  default     = true
  type        = bool
}

variable "runner_schedule_config" {
  description = "Map containing the configuration of the ASG scale-out and scale-in for the Runner. Will only be used if `agent_schedule_enable` is set to `true`. "
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

variable "runner_install" {
  description = <<-EOT
    amazon_ecr_credentials_helper = Install amazon-ecr-credential-helper inside `userdata_pre_install` script
    docker_machine_download_url = URL to download docker machine binary. If not set, the docker machine version will be used to download the binary.
    docker_machine_version = By default docker_machine_download_url is used to set the docker machine version. This version will be ignored once `docker_machine_download_url` is set. The version number is maintained by the CKI project. Check out at https://gitlab.com/cki-project/docker-machine/-/releases
    pre_install_script = Script to run before installing the Runner
    post_install_script = Script to run after installing the Runner
    start_script = Script to run after starting the Runner
    yum_update = Update the yum packages before installing the Runner
  EOT
  type = object({
    amazon_ecr_credential_helper = optional(bool, false)
    docker_machine_download_url  = optional(string, "")
    docker_machine_version       = optional(string, "0.16.2-gitlab.19-cki.2")
    pre_install_script           = optional(string, "")
    post_install_script          = optional(string, "")
    start_script                 = optional(string, "")
    yum_update                   = optional(bool, true)
  })
  default = {}
}

variable "runner_cloudwatch" {
  description = <<-EOT
    enable = Boolean used to enable or disable the CloudWatch logging.
    log_group_name = Option to override the default name (`environment`) of the log group. Requires `enable = true`.
    retention_days = Retention for cloudwatch logs. Defaults to unlimited. Requires `enable = true`.
  EOT
  type = object({
    enable         = optional(bool, true)
    log_group_name = optional(string, null)
    retention_days = optional(number, 0)
  })
  default = {}
}

variable "runner_gitlab_registration_config" {
  description = "Configuration used to register the Runner. See the README for an example, or reference the examples in the examples directory of this repo. There is also a good GitLab documentation available at: https://docs.gitlab.com/ee/ci/runners/configure_runners.html"
  type = object({
    registration_token = optional(string, "__GITLAB_REGISTRATION_TOKEN_FROM_SSM__")
    tag_list           = optional(string, "")
    description        = optional(string, "")
    type               = optional(string, "") # mandatory if gitlab_runner_version >= 16.0.0
    group_id           = optional(string, "") # mandatory if type is group
    project_id         = optional(string, "") # mandatory if type is project
    locked_to_project  = optional(string, "")
    run_untagged       = optional(string, "")
    maximum_timeout    = optional(string, "")
    access_level       = optional(string, "not_protected") # this is the only mandatory field calling the GitLab get token for executor operation
  })

  default = {}
  validation {
    condition     = contains(["group", "project", "instance", ""], var.runner_gitlab_registration_config.type)
    error_message = "The executor currently supports `group`, `project` or `instance`."
  }
}

variable "runner_gitlab" {
  description = <<-EOT
    ca_certificate = Trusted CA certificate bundle (PEM format).
    certificate = Certificate of the GitLab instance to connect to (PEM format).
    registration_token = Registration token to use to register the Runner. Do not use. This is replaced by the `registration_token` in `runner_gitlab_registration_config`.
    runner_version = Version of the [GitLab Runner](https://gitlab.com/gitlab-org/gitlab-runner/-/releases).
    url = URL of the GitLab instance to connect to.
    url_clone = URL of the GitLab instance to clone from. Use only if the agent can’t connect to the GitLab URL.
    access_token_secure_parameter_store_name = The name of the SSM parameter to read the GitLab access token from. It must have the `api` scope and be pre created.
  EOT
  type = object({
    ca_certificate                           = optional(string, "")
    certificate                              = optional(string, "")
    registration_token                       = optional(string, "__REPLACED_BY_USER_DATA__")
    runner_version                           = optional(string, "15.8.2")
    url                                      = optional(string, "")
    url_clone                                = optional(string, "")
    access_token_secure_parameter_store_name = optional(string, "gitlab-runner-access-token")
  })
}

variable "runner_gitlab_registration_token_secure_parameter_store_name" {
  description = "The name of the SSM parameter to read the GitLab Runner registration token from."
  type        = string
  default     = "gitlab-runner-registration-token"
}

variable "runner_gitlab_token_secure_parameter_store" {
  description = "Name of the Secure Parameter Store entry to hold the GitLab Runner token."
  type        = string
  default     = "runner-token"
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
  description = "Timeout when trying to delete the Runner ASG."
  default     = "10m"
  type        = string
}

/*
 * Runner Worker: The process created by the Runner on the host computing platform to run jobs.
 */
variable "runner_worker" {
  description = <<-EOT
    For detailed information, check https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section.

    environment_variables = List of environment variables to add to the Runner Worker (environment).
    max_jobs = Number of jobs which can be processed in parallel by the Runner Worker.
    output_limit = Sets the maximum build log size in kilobytes. Default is 4MB (output_limit).
    request_concurrency = Limit number of concurrent requests for new jobs from GitLab (default 1) (request_concurrency).
    ssm_access = Allows to connect to the Runner Worker via SSM.
    type = The Runner Worker type to use. Currently supports `docker+machine` or `docker`.
  EOT
  type = object({
    environment_variables = optional(list(string), [])
    max_jobs              = optional(number, 0)
    output_limit          = optional(number, 4096)
    request_concurrency   = optional(number, 1)
    ssm_access            = optional(bool, false)
    type                  = optional(string, "docker+machine")
  })
  default = {}

  validation {
    condition     = contains(["docker+machine", "docker"], var.runner_worker.type)
    error_message = "The executor currently supports `docker+machine` and `docker`."
  }
}

variable "runner_worker_cache" {
  description = <<-EOT
    Configuration to control the creation of the cache bucket. By default the bucket will be created and used as shared
    cache. To use the same cache across multiple Runner Worker disable the creation of the cache and provide a policy and
    bucket name. See the public runner example for more details."

    For detailed documentation check https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runnerscaches3-section

    access_log_bucker_id = The ID of the bucket where the access logs are stored.
    access_log_bucket_prefix = The bucket prefix for the access logs.
    authentication_type = A string that declares the AuthenticationType for [runners.cache.s3]. Can either be 'iam' or 'credentials'
    bucket = Name of the cache bucket. Requires `create = false`.
    bucket_prefix = Prefix for s3 cache bucket name. Requires `create = true`.
    create = Boolean used to enable or disable the creation of the cache bucket.
    expiration_days = Number of days before cache objects expire. Requires `create = true`.
    include_account_id = Boolean used to include the account id in the cache bucket name. Requires `create = true`.
    policy = Policy to use for the cache bucket. Requires `create = false`.
    random_suffix = Boolean used to enable or disable the use of a random string suffix on the cache bucket name. Requires `create = true`.
    shared = Boolean used to enable or disable the use of the cache bucket as shared cache.
    versioning = Boolean used to enable versioning on the cache bucket. Requires `create = true`.
  EOT
  type = object({
    access_log_bucket_id     = optional(string, null)
    access_log_bucket_prefix = optional(string, null)
    authentication_type      = optional(string, "iam")
    bucket                   = optional(string, "")
    bucket_prefix            = optional(string, "")
    create                   = optional(bool, true)
    expiration_days          = optional(number, 1)
    include_account_id       = optional(bool, true)
    policy                   = optional(string, "")
    random_suffix            = optional(bool, false)
    shared                   = optional(bool, false)
    versioning               = optional(bool, false)
  })
  default = {}
}

variable "runner_worker_gitlab_pipeline" {
  description = <<-EOT
    post_build_script = Script to execute in the pipeline just after the build, but before executing after_script.
    pre_build_script = Script to execute in the pipeline just before the build.
    pre_clone_script = Script to execute in the pipeline before cloning the Git repository. this can be used to adjust the Git client configuration first, for example.
  EOT
  type = object({
    post_build_script = optional(string, "\"\"")
    pre_build_script  = optional(string, "\"\"")
    pre_clone_script  = optional(string, "\"\"")
  })
  default = {}
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
    Options added to the [runners.docker] section of config.toml to configure the Docker container of the Runner Worker. For
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
 * docker+machine Runner Worker variables. The Runner Worker is the actual machine that runs the job. Please specify the
 * `runner_worker_docker_*` variables as well as Docker is used on the docker+machine Runner Worker.
 */
variable "runner_worker_docker_machine_fleet" {
  description = <<-EOT
    enable = Activates the fleet mode on the Runner. https://gitlab.com/cki-project/docker-machine/-/blob/v0.16.2-gitlab.19-cki.2/docs/drivers/aws.md#fleet-mode
    key_pair_name = The name of the key pair used by the Runner to connect to the docker-machine Runner Workers. This variable is only supported when `enables` is set to `true`.
  EOT
  type = object({
    enable        = bool
    key_pair_name = optional(string, "fleet-key")
  })
  default = {
    enable = false
  }
}

variable "runner_worker_docker_machine_role" {
  description = <<-EOT
    additional_tags = Map of tags that will be added to the Runner Worker.
    assume_role_policy_json = Assume role policy for the Runner Worker.
    policy_arns = List of ARNs of IAM policies to attach to the Runner Workers.
    profile_name    = Name of the IAM profile to attach to the Runner Workers.
  EOT
  type = object({
    additional_tags         = optional(map(string), {})
    assume_role_policy_json = optional(string, "")
    policy_arns             = optional(list(string), [])
    profile_name            = optional(string, "")
  })
  default = {}
}

variable "runner_worker_docker_machine_extra_egress_rules" {
  description = "List of egress rules for the Runner Workers."
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
      description      = "Allow all egress traffic for Runner Workers."
    }
  ]
}

variable "runner_worker_docker_machine_security_group_description" {
  description = "A description for the Runner Worker security group"
  type        = string
  default     = "A security group containing Runner Worker instances"
}

variable "runner_worker_docker_machine_ami_filter" {
  description = "List of maps used to create the AMI filter for the Runner Worker."
  type        = map(list(string))

  default = {
    name = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

variable "runner_worker_docker_machine_ami_owners" {
  description = "The list of owners used to select the AMI of the Runner Worker."
  type        = list(string)

  # Canonical
  default = ["099720109477"]
}

variable "runner_worker_docker_machine_instance" {
  description = <<-EOT
    For detailed documentation check https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runnersmachine-section

    docker_registry_mirror_url = The URL of the Docker registry mirror to use for the Runner Worker.
    destroy_after_max_builds = Destroy the instance after the maximum number of builds has been reached.
    ebs_optimized = Enable EBS optimization for the Runner Worker.
    idle_count = Number of idle Runner Worker instances (not working for the Docker Runner Worker) (IdleCount).
    idle_time = Idle time of the Runner Worker before they are destroyed (not working for the Docker Runner Worker) (IdleTime).
    max_growth_rate = The maximum number of machines that can be added to the runner in parallel.
    monitoring = Enable detailed monitoring for the Runner Worker.
    name_prefix = Set the name prefix and override the `Name` tag for the Runner Worker.
    private_address_only = Restrict Runner Worker to the use of a private IP address. If `runner_instance.use_private_address_only` is set to `true` (default), `runner_worker_docker_machine_instance.private_address_only` will also apply for the Runner.
    root_size = The size of the root volume for the Runner Worker.
    start_script = Cloud-init user data that will be passed to the Runner Worker. Should not be base64 encrypted.
    subnet_ids = The list of subnet IDs to use for the Runner Worker when the fleet mode is enabled.
    types = The type of instance to use for the Runner Worker. In case of fleet mode, multiple instance types are supported.
    volume_type = The type of volume to use for the Runner Worker.
  EOT
  type = object({
    destroy_after_max_builds   = optional(number, 0)
    docker_registry_mirror_url = optional(string, "")
    ebs_optimized              = optional(bool, true)
    idle_count                 = optional(number, 0)
    idle_time                  = optional(number, 600)
    max_growth_rate            = optional(number, 0)
    monitoring                 = optional(bool, false)
    name_prefix                = optional(string, "")
    private_address_only       = optional(bool, true)
    root_size                  = optional(number, 8)
    start_script               = optional(string, "")
    subnet_ids                 = optional(list(string), [])
    types                      = optional(list(string), ["m5.large"])
    volume_type                = optional(string, "gp2")
  })
  default = {
  }

  validation {
    condition     = length(var.runner_worker_docker_machine_instance.name_prefix) <= 28
    error_message = "Maximum length for docker+machine executor name is 28 characters!"
  }

  validation {
    condition     = var.runner_worker_docker_machine_instance.name_prefix == "" || can(regex("^[a-zA-Z0-9\\.-]+$", var.runner_worker_docker_machine_instance.name_prefix))
    error_message = "Valid characters for the docker+machine executor name are: [a-zA-Z0-9\\.-]."
  }
}

variable "runner_worker_docker_machine_instance_spot" {
  description = <<-EOT
    enable = Enable spot instances for the Runner Worker.
    max_price = The maximum price willing to pay. By default the price is limited by the current on demand price for the instance type chosen.
  EOT
  type = object({
    enable    = optional(bool, true)
    max_price = optional(string, "on-demand-price")
  })
  default = {}
}

variable "runner_worker_docker_machine_ec2_options" {
  description = "List of additional options for the docker+machine config. Each element of this list must be a key=value pair. E.g. '[\"amazonec2-zone=a\"]'"
  type        = list(string)
  default     = []
}

variable "runner_worker_docker_machine_ec2_metadata_options" {
  description = "Enable the Runner Worker metadata service. Requires you use CKI maintained docker machines."
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

variable "debug" {
  description = <<-EOT
    trace_runner_user_data: Enable bash trace for the user data script on the Agent. Be aware this could log sensitive data such as you GitLab runner token.
    write_runner_config_to_file: When enabled, outputs the rendered config.toml file in the root module. Note that enabling this can
                                 potentially expose sensitive information.
    write_runner_user_data_to_file: When enabled, outputs the rendered userdata.sh file in the root module. Note that enabling this
                                    can potentially expose sensitive information.
  EOT
  type = object({
    trace_runner_user_data         = optional(bool, false)
    write_runner_config_to_file    = optional(bool, false)
    write_runner_user_data_to_file = optional(bool, false)
  })
  default = {}
}

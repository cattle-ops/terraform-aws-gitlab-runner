variable "aws_region" {
  description = "AWS region."
  type        = string
}

variable "aws_zone" {
  description = "AWS availability zone (typically 'a', 'b', or 'c')."
  type        = string
  default     = "a"
}

variable "environment" {
  description = "A name that identifies the environment, used as prefix and for tagging."
  type        = string
}

variable "vpc_id" {
  description = "The target VPC for the docker-machine and runner instances."
  type        = string
}

variable "subnet_id_runners" {
  description = "List of subnets used for hosting the gitlab-runners."
  type        = string
}

variable "subnet_ids_gitlab_runner" {
  description = "Subnet used for hosting the GitLab runner."
  type        = list(string)
}

variable "instance_type" {
  description = "Instance type used for the GitLab runner."
  type        = string
  default     = "t3.micro"
}

variable "runner_instance_spot_price" {
  description = "By setting a spot price bid price the runner agent will be created via a spot request. Be aware that spot instances can be stopped by AWS."
  type        = string
  default     = ""
}

variable "ssh_key_pair" {
  description = "Set this to use existing AWS key pair"
  type        = string
  default     = ""
}

variable "ssh_public_key" {
  description = "Public SSH key used for the GitLab runner EC2 instance."
  type        = string
  default     = ""
}

variable "docker_machine_instance_type" {
  description = "Instance type used for the instances hosting docker-machine."
  type        = string
  default     = "m5a.large"
}

variable "docker_machine_spot_price_bid" {
  description = "Spot price bid."
  type        = string
  default     = "0.06"
}

variable "docker_machine_version" {
  description = "Version of docker-machine."
  type        = string
  default     = "0.16.2"
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

variable "runners_additional_volumes" {
  description = "Additional volumes that will be used in the runner config.toml, e.g Docker socket"
  type        = list
  default     = []
}

variable "runners_shm_size" {
  description = "shm_size for the runners, will be used in the runner config.toml"
  type        = number
  default     = 0
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

variable "runners_off_peak_timezone" {
  description = "Off peak idle time zone of the runners, will be used in the runner config.toml."
  type        = string
  default     = ""
}

variable "runners_off_peak_idle_count" {
  description = "Off peak idle count of the runners, will be used in the runner config.toml."
  type        = number
  default     = 0
}

variable "runners_off_peak_idle_time" {
  description = "Off peak idle time of the runners, will be used in the runner config.toml."
  type        = number
  default     = 0
}

variable "runners_off_peak_periods" {
  description = "Off peak periods of the runners, will be used in the runner config.toml."
  type        = string
  default     = ""
}

variable "runners_root_size" {
  description = "Runner instance root size in GB."
  type        = number
  default     = 16
}

variable "create_runners_iam_instance_profile" {
  description = "Boolean to control the creation of the runners IAM instance profile"
  type        = bool
  default     = true
}

variable "runners_iam_instance_profile_name" {
  description = "IAM instance profile name of the runners, will be used in the runner config.toml"
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
  default     = ""
}

variable "runners_post_build_script" {
  description = "Commands to be executed on the Runner just after executing the build, but before executing after_script. "
  type        = string
  default     = ""
}

variable "runners_pre_clone_script" {
  description = "Commands to be executed on the Runner before cloning the Git repository. this can be used to adjust the Git client configuration first, for example. "
  type        = string
  default     = ""
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
  description = "Restrict runners to the use of a private IP address"
  type        = bool
  default     = true
}

variable "docker_machine_user" {
  description = "Username of the user used to create the spot instances that host docker-machine."
  type        = string
  default     = "docker-machine"
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
  description = "Version of the GitLab runner."
  type        = string
  default     = "12.3.0"
}

variable "enable_gitlab_runner_ssh_access" {
  description = "Enables SSH Access to the gitlab runner instance."
  type        = bool
  default     = false
}

variable "gitlab_runner_ssh_cidr_blocks" {
  description = "List of CIDR blocks to allow SSH Access to the gitlab runner instance."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "docker_machine_docker_cidr_blocks" {
  description = "List of CIDR blocks to allow Docker Access to the docker machine runner instance."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "docker_machine_ssh_cidr_blocks" {
  description = "List of CIDR blocks to allow SSH Access to the docker machine runner instance."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_cloudwatch_logging" {
  description = "Boolean used to enable or disable the CloudWatch logging."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Map of tags that will be added to created resources. By default resources will be tagged with name and environment."
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

variable "ami_filter" {
  description = "List of maps used to create the AMI filter for the Gitlab runner agent AMI. Currently Amazon Linux 2 `amzn2-ami-hvm-2.0.????????-x86_64-ebs` looks to *not* be working for this configuration."
  type        = map(list(string))

  default = {
    name = ["amzn-ami-hvm-2018.03*-x86_64-ebs"]
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
    name = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
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

variable "enable_manage_gitlab_token" {
  description = "Boolean to enable the management of the GitLab token in SSM. If `true` the token will be stored in SSM, which means the SSM property is a terraform managed resource. If `false` the Gitlab token will be stored in the SSM by the user-data script during creation of the the instance. However the SSM parameter is not managed by terraform and will remain in SSM after a `terraform destroy`."
  type        = bool
  default     = true
}

variable "overrides" {
  description = "This maps provides the possibility to override some defaults. The following attributes are supported: `name_sg` overwrite the `Name` tag for all security groups created by this module. `name_runner_agent_instance` override the `Name` tag for the ec2 instance defined in the auto launch configuration. `name_docker_machine_runners` ovverrid the `Name` tag spot instances created by the runner agent."
  type        = map(string)

  default = {
    name_sg                     = ""
    name_runner_agent_instance  = ""
    name_docker_machine_runners = ""
  }
}

variable "cache_bucket" {
  description = "Configuration to control the creation of the cache bucket. By default the bucket will be created and used as shared cache. To use the same cache cross multiple runners disable the cration of the cache and provice a policy and bucket name. See the public runner example for more details."
  type        = map

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
  type        = map
  default = {
    scale_in_recurrence  = "0 18 * * 1-5"
    scale_in_count       = 0
    scale_out_recurrence = "0 8 * * 1-5"
    scale_out_count      = 1
  }
}

variable "runner_root_block_device" {
  description = "The EC2 instance root block device configuration. Takes the following keys: `delete_on_termination`, `volume_type`, `volume_size`, `iops`"
  type        = map(string)
  default     = {}
}

variable "enable_runner_ssm_access" {
  description = "Add IAM policies to the runner agent instance to connect via the Session Manager."
  type        = bool
  default     = false
}

variable "runners_volumes_tmpfs" {
  description = "Mount temporary file systems to the main containers. Must consist of pairs of strings e.g. \"/var/lib/mysql\" = \"rw,noexec\", see example"
  type        = "list"
  default     = []
}

variable "runners_services_volumes_tmpfs" {
  description = "Mount temporary file systems to service containers. Must consist of pairs of strings e.g. \"/var/lib/mysql\" = \"rw,noexec\", see example"
  type        = "list"
  default     = []
}

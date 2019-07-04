variable "aws_region" {
  description = "AWS region."
  type        = "string"
}

variable "aws_zone" {
  description = "AWS availability zone (typically 'a', 'b', or 'c')."
  type        = "string"
  default     = "a"
}

variable "environment" {
  description = "A name that identifies the environment, used as prefix and for tagging."
  type        = "string"
}

variable "vpc_id" {
  description = "The target VPC for the docker-machine and runner instances."
  type        = "string"
}

variable "subnet_id_runners" {
  description = "List of subnets used for hosting the gitlab-runners."
  type        = "string"
}

variable "subnet_ids_gitlab_runner" {
  description = "Subnet used for hosting the GitLab runner."
  type        = "list"
}

variable "instance_type" {
  description = "Instance type used for the GitLab runner."
  type        = "string"
  default     = "t3.micro"
}

variable "runner_instance_spot_price" {
  description = "By setting a spot price bid price the runner agent will be created via a spot request. Be aware that spot instances can be stopped by AWS."
  type        = "string"
  default     = ""
}

variable "ssh_public_key" {
  description = "Public SSH key used for the GitLab runner EC2 instance."
  type        = "string"
}

variable "docker_machine_instance_type" {
  description = "Instance type used for the instances hosting docker-machine."
  default     = "m5a.large"
}

variable "docker_machine_spot_price_bid" {
  description = "Spot price bid."
  default     = "0.06"
}

variable "docker_machine_version" {
  description = "Version of docker-machine."
  default     = "0.16.1"
}

variable "runners_name" {
  description = "Name of the runner, will be used in the runner config.toml."
  type        = "string"
}

variable "runners_executor" {
  description = "The executor to use. Currently supports `docker+machine` or `docker`."
  type        = "string"
  default     = "docker+machine"
}

variable "runners_gitlab_url" {
  description = "URL of the GitLab instance to connect to."
  type        = "string"
}

variable "runners_token" {
  description = "Token for the runner, will be used in the runner config.toml."
  type        = "string"
  default     = "__REPLACED_BY_USER_DATA__"
}

variable "runners_limit" {
  description = "Limit for the runners, will be used in the runner config.toml."
  default     = 0
}

variable "runners_concurrent" {
  description = "Concurrent value for the runners, will be used in the runner config.toml."
  default     = 10
}

variable "runners_idle_time" {
  description = "Idle time of the runners, will be used in the runner config.toml."
  default     = 600
}

variable "runners_idle_count" {
  description = "Idle count of the runners, will be used in the runner config.toml."
  default     = 0
}

variable "runners_image" {
  description = "Image to run builds, will be used in the runner config.toml"
  type        = "string"
  default     = "docker:18.03.1-ce"
}

variable "runners_privileged" {
  description = "Runners will run in privileged mode, will be used in the runner config.toml"
  type        = "string"
  default     = "true"
}

variable "runners_shm_size" {
  description = "shm_size for the runners.  will be used in the runner config.toml"
  default     = 0
}

variable "runners_pull_policy" {
  description = "pull_policy for the runners.  will be used in the runner config.toml"
  type        = "string"
  default     = "always"
}

variable "runners_monitoring" {
  description = "Enable detailed cloudwatch monitoring for spot instances."
  default     = false
}

variable "runners_off_peak_timezone" {
  description = "Off peak idle time zone of the runners, will be used in the runner config.toml."
  default     = ""
}

variable "runners_off_peak_idle_count" {
  description = "Off peak idle count of the runners, will be used in the runner config.toml."
  default     = 0
}

variable "runners_off_peak_idle_time" {
  description = "Off peak idle time of the runners, will be used in the runner config.toml."
  default     = 0
}

variable "runners_off_peak_periods" {
  description = "Off peak periods of the runners, will be used in the runner config.toml."
  type        = "string"
  default     = ""
}

variable "runners_root_size" {
  description = "Runner instance root size in GB."
  default     = 16
}

variable "create_runners_iam_instance_profile" {
  description = "Boolean to control the creation of the runners IAM instance profile"
  default     = true
}

variable "runners_iam_instance_profile_name" {
  description = "IAM instance profile name of the runners, will be used in the runner config.toml"
  type        = "string"
  default     = ""
}

variable "runners_environment_vars" {
  description = "Environment variables during build execution, e.g. KEY=Value, see runner-public example. Will be used in the runner config.toml"
  type        = "list"
  default     = []
}

variable "runners_pre_build_script" {
  description = "Script to execute in the pipeline just before the build, will be used in the runner config.toml"
  type        = "string"
  default     = ""
}

variable "runners_post_build_script" {
  description = "Commands to be executed on the Runner just after executing the build, but before executing after_script. "
  type        = "string"
  default     = ""
}

variable "runners_pre_clone_script" {
  description = "Commands to be executed on the Runner before cloning the Git repository. this can be used to adjust the Git client configuration first, for example. "
  type        = "string"
  default     = ""
}

variable "runners_request_concurrency" {
  description = "Limit number of concurrent requests for new jobs from GitLab (default 1)"
  default     = "1"
}

variable "runners_output_limit" {
  description = "Sets the maximum build log size in kilobytes, by default set to 4096 (4MB)"
  default     = "4096"
}

variable "userdata_pre_install" {
  description = "User-data script snippet to insert before GitLab runner install"
  type        = "string"
  default     = ""
}

variable "userdata_post_install" {
  description = "User-data script snippet to insert after GitLab runner install"
  type        = "string"
  default     = ""
}

variable "runners_use_private_address" {
  description = "Restrict runners to the use of a private IP address"
  default     = "true"
}

variable "docker_machine_user" {
  description = "Username of the user used to create the spot instances that host docker-machine."
  type        = "string"
  default     = "docker-machine"
}

variable "cache_bucket_prefix" {
  description = "Prefix for s3 cache bucket name."
  type        = "string"
  default     = ""
}

variable "cache_bucket_versioning" {
  description = "Boolean used to enable versioning on the cache bucket, false by default."
  type        = "string"
  default     = "false"
}

variable "cache_expiration_days" {
  description = "Number of days before cache objects expires."
  default     = 1
}

variable "cache_shared" {
  description = "Enables cache sharing between runners, false by default."
  type        = "string"
  default     = "false"
}

variable "gitlab_runner_version" {
  description = "Version of the GitLab runner."
  type        = "string"
  default     = "11.11.2"
}

variable "enable_gitlab_runner_ssh_access" {
  description = "Enables SSH Access to the gitlab runner instance."
  default     = false
}

variable "gitlab_runner_ssh_cidr_blocks" {
  description = "List of CIDR blocks to allow SSH Access from to the gitlab runner instance."
  type        = "list"
  default     = ["0.0.0.0/0"]
}

variable "enable_cloudwatch_logging" {
  description = "Boolean used to enable or disable the CloudWatch logging."
  default     = true
}

variable "tags" {
  type        = "map"
  description = "Map of tags that will be added to created resources. By default resources will be tagged with name and environment."
  default     = {}
}

variable "allow_iam_service_linked_role_creation" {
  description = "Boolean used to control attaching the policy to a runner instance to create service linked roles."
  default     = true
}

variable "docker_machine_options" {
  description = "List of additional options for the docker machine config. Each element of this list must be a key=value pair. E.g. '[\"amazonec2-zone=a\"]'"
  type        = "list"
  default     = []
}

variable "instance_role_json" {
  description = "Docker machine runner instance override policy, expected to be in JSON format."
  type        = "string"
  default     = ""
}

variable "instance_role_runner_json" {
  description = "Instance role json for the docker machine runners to override the default."
  type        = "string"
  default     = ""
}

variable "ami_filter" {
  description = "List of maps used to create the AMI filter for the Gitlab runner agent AMI. Currently Amazon Linux 2 `amzn2-ami-hvm-2.0.????????-x86_64-ebs` looks to *not* be working for this configuration."
  type        = "list"

  default = [{
    name   = "name"
    values = ["amzn-ami-hvm-2018.03*-x86_64-ebs"]
  }]
}

variable "ami_owners" {
  description = "The list of owners used to select the AMI of Gitlab runner agent instances."
  type        = "list"
  default     = ["amazon"]
}

variable "runner_ami_filter" {
  description = "List of maps used to create the AMI filter for the Gitlab runner docker-machine AMI."
  type        = "list"

  default = [{
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }]
}

variable "runner_ami_owners" {
  description = "The list of owners used to select the AMI of Gitlab runner docker-machine instances."
  type        = "list"

  # Canonical
  default = ["099720109477"]
}

variable "gitlab_runner_registration_config" {
  description = "Configuration used to register the runner. See the README for an example, or reference the examples in the examples directory of this repo."
  type        = "map"

  default = {
    registration_token = ""
    tag_list           = ""
    description        = ""
    locked_to_project  = ""
    run_untagged       = ""
    maximum_timeout    = ""
  }
}

variable "secure_parameter_store_runner_token_key" {
  type        = "string"
  description = "The key name used store the Gitlab runner token in Secure Parameter Store"
  default     = "runner-token"
}

variable "enable_manage_gitlab_token" {
  description = "Boolean to enable the management of the GitLab token in SSM. If `true` the token will be stored in SSM, which means the SSM property is a terraform managed resource. If `false` the Gitlab token will be stored in the SSM by the user-data script during creation of the the instance. However the SSM parameter is not managed by terraform and will remain in SSM after a `terraform destroy`."
  default     = true
}

variable "name_runners_docker_machine" {
  default = ""
}

variable "overrides" {
  description = "This maps provides the possibility to override some defaults. The following attributes are supported: `name_sg` overwrite the `Name` tag for all security groups created by this module. `name_runner_agent_instance` override the `Name` tag for the ec2 instance defined in the auto launch configuration. `name_docker_machine_runners` ovverrid the `Name` tag spot instances created by the runner agent."
  type        = "map"

  default = {
    name_sg                     = ""
    name_runner_agent_instance  = ""
    name_docker_machine_runners = ""
  }
}

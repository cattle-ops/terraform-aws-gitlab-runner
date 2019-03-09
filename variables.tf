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
  description = "Subnet used to host the docker-machine gitlab-runners."
  type        = "string"
}

variable "subnet_ids_gitlab_runner" {
  description = "List of subnets used for hosting the gitlab-runners."
  type        = "list"
}

variable "instance_type" {
  description = "Instance type used for the GitLab runner."
  type        = "string"
  default     = "t2.micro"
}

variable "ssh_public_key" {
  description = "Public SSH key used for the GitLab runner ec2 instance."
  type        = "string"
}

variable "docker_machine_instance_type" {
  description = "Instance type used for the instances hosting docker-machine."
  default     = "m4.large"
}

variable "docker_machine_spot_price_bid" {
  description = "Spot price bid."
  default     = "0.04"
}

variable "docker_machine_version" {
  description = "Version of docker-machine."
  default     = "0.16.1"
}

variable "runners_name" {
  description = "Name of the runner, will be used in the runner config.toml"
  type        = "string"
}

variable "runners_executor" {
  description = "The executor to use. Currently supports docker+machine or docker"
  type        = "string"
  default     = "docker+machine"
}

variable "runners_gitlab_url" {
  description = "URL of the Gitlab instance to connect to."
  type        = "string"
}

variable "runners_token" {
  description = "Token for the runner, will be used in the runner config.toml"
  type        = "string"
  default     = "__REPLACED_BY_USER_DATA__"
}

variable "runners_limit" {
  description = "Limit for the runners, will be used in the runner config.toml"
  default     = 0
}

variable "runners_concurrent" {
  description = "Concurrent value for the runners, will be used in the runner config.toml"
  default     = 10
}

variable "runners_idle_time" {
  description = "Idle time of the runners, will be used in the runner config.toml"
  default     = 600
}

variable "runners_idle_count" {
  description = "Idle count of the runners, will be used in the runner config.toml"
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
  description = "Version of the Gitlab runner."
  type        = "string"
  default     = "11.8.0"
}

variable "enable_cloudwatch_logging" {
  description = "Boolean used to enable or disable the CloudWatch logging."
  default     = true
}

variable "tags" {
  type        = "map"
  description = "Map of tags that will be added to module created resources. By default resources will be tagged with 'name' and 'environemnt'."
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
  description = "Runner agent instance override policy, expected to be in JSON format. "
  type        = "string"
  default     = ""
}

variable "instance_role_runner_json" {
  description = "Docker machine runner instance override policy, expected to be in JSON format."
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

variable "gitlab_runner_registration_config" {
  description = "Configuration used to register the runner. See the README for an example, or reference the examples in the examples directory of this repo."
  type        = "map"

  default = {
    registration_token = ""
    tag_list           = ""
    description        = ""
    locked_to_project  = "true"
    run_untagged       = "false"
    maximum_timeout    = "3600"
  }
}

variable "allow_all_inbound" {
  description = "Boolean used to enable all inbound traffic"
  default     = false
}

variable "secure_parameter_store_runner_token_key" {
  type        = "string"
  description = "The key name used store the Gitlab runner token in Secure Parameter Store"
  default     = "runner-token"
}

variable "gitlab_runner_registration_config" {
  description = "Configuration used to register the runner. See the README for an example, or reference the examples in the examples directory of this repo."
  type        = "map"

  default = {
    registration_token = ""
    tag_list           = ""
    description        = ""
    locked_to_project  = "true"
    run_untagged       = "false"
    maximum_timeout    = "3600"
  }
}

variable "allow_ssh_to_runner_instance_sg" {
  type        = "string"
  description = "Security group to attach to the runner instance ssh sg to allow remote access."
  default     = ""
}

variable "ssh_key_name" {
  type        = "string"
  description = "Name of the SSH key to associate with the instances."
}

variable "specified_cidr_blocks" {
  type        = "list"
  description = "List of additional subnets in CDIR notation to allow inbound ssh access to the gitlab-runner host."
  default     = []
}

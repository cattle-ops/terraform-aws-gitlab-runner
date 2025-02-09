variable "docker_machine_tags" {
    description = "The tags to apply to the docker machine."
    type        = map(string)
}

variable "docker_machine_fleet_launch_template_name" {
    description = "The name of the launch template for the docker machine fleet."
    type        = string
}

variable "docker_machine_ami_id" {
    description = "The AMI ID to use for the docker machine workers."
    type        = string
}

variable "docker_machine_security_group_name" {
    description = "The name of the security group for the docker machine."
    type        = string
}

variable "docker_machine_instance_profile_name" {
    description = "The name of the instance profile for the docker machine."
    type        = string
}

variable "docker_machine_availability_zone_name" {
    description = "The name of the availability zone for the docker machine."
    type        = string
}

variable "docker_machine_runner_name" {
    description = "The name of the instance."
    type        = string
}

variable "docker_autoscaler_asg_name" {
    description = "The name of the autoscaling group for the docker autoscaler."
    type        = string
}

variable "cache_bucket_name" {
    description = "The name of the S3 bucket to use for caching."
    type        = string
}

variable "kms_key_arn" {
    description = "The ARN of the KMS key to use for encrypting everything."
    type        = string
}

variable "docker_machine_instance" {
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
    root_device_name = The name of the root volume for the Runner Worker.
    root_size = The size of the root volume for the Runner Worker.
    start_script = Cloud-init user data that will be passed to the Runner Worker. Should not be base64 encrypted.
    subnet_ids = The list of subnet IDs to use for the Runner Worker when the fleet mode is enabled.
    types = The type of instance to use for the Runner Worker. In case of fleet mode, multiple instance types are supported.
    volume_type = The type of volume to use for the Runner Worker. `gp2`, `gp3`, `io1` or `io2` are supported.
    volume_throughput = Throughput in MB/s for the volume. Only supported when using `gp3` as `volume_type`.
    volume_iops = Guaranteed IOPS for the volume. Only supported when using `gp3`, `io1` or `io2` as `volume_type`. Works for fleeting only. See `runner_worker_docker_machine_fleet`.
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
        root_device_name           = optional(string, "/dev/sda1")
        root_size                  = optional(number, 8)
        start_script               = optional(string, "")
        subnet_ids                 = optional(list(string), [])
        types                      = optional(list(string), ["m5.large"])
        volume_type                = optional(string, "gp2")
        volume_throughput          = optional(number, 125)
        volume_iops                = optional(number, 3000)
    })
    default = {
    }

    validation {
        condition     = length(var.docker_machine_instance.name_prefix) <= 28
        error_message = "Maximum length for docker+machine executor name is 28 characters!"
    }

    validation {
        condition     = var.docker_machine_instance.name_prefix == "" || can(regex("^[a-zA-Z0-9\\.-]+$", var.docker_machine_instance.name_prefix))
        error_message = "Valid characters for the docker+machine executor name are: [a-zA-Z0-9\\.-]."
    }

    validation {
        condition     = contains(["gp2", "gp3", "io1", "io2"], var.docker_machine_instance.volume_type)
        error_message = "Supported volume types: gp2, gp3, io1 and io2"
    }
}

variable "runner_worker" {
    description = <<-EOT
    For detailed information, check https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section.

    environment_variables = List of environment variables to add to the Runner Worker (environment).
    max_jobs = Number of jobs which can be processed in parallel by the Runner Worker.
    output_limit = Sets the maximum build log size in kilobytes. Default is 4MB (output_limit).
    request_concurrency = Limit number of concurrent requests for new jobs from GitLab (default 1) (request_concurrency).
    ssm_access = Allows to connect to the Runner Worker via SSM.
    type = The Runner Worker type to use. Currently supports `docker+machine` or `docker` or `docker-autoscaler`.
    use_private_key = Use a private key to connect the Runner Manager to the Runner Workers. Ignored when fleeting is enabled (defaults to `true`).
  EOT
    type = object({
        environment_variables = optional(list(string), [])
        max_jobs              = optional(number, 0)
        output_limit          = optional(number, 4096)
        request_concurrency   = optional(number, 1)
        ssm_access            = optional(bool, false)
        type                  = optional(string, "docker+machine")
        # false positive, use_private_key is not a secret
        # kics-scan ignore-line
        use_private_key = optional(bool, false)
    })
    default = {}

    validation {
        condition     = contains(["docker+machine", "docker", "docker-autoscaler"], var.runner_worker.type)
        error_message = "The executor currently supports `docker+machine` and `docker`."
    }
}

variable "runner_worker_docker_autoscaler" {
    description = <<-EOT
    fleeting_plugin_version = The version of aws fleeting plugin.
    connector_config_user = User to connect to worker machine.
    key_pair_name = The name of the key pair used by the Runner to connect to the docker-machine Runner Workers. This variable is only supported when `enables` is set to `true`.
    capacity_per_instance = The number of jobs that can be executed concurrently by a single instance.
    max_use_count = Max job number that can run on a worker.
    update_interval = The interval to check with the fleeting plugin for instance updates.
    update_interval_when_expecting = The interval to check with the fleeting plugin for instance updates when expecting a state change.
    instance_ready_command = Executes this command on each instance provisioned by the autoscaler to ensure that it is ready for use. A failure results in the instance being removed.
  EOT
    type = object({
        fleeting_plugin_version        = optional(string, "1.0.0")
        connector_config_user          = optional(string, "ec2-user")
        key_pair_name                  = optional(string, "runner-worker-key")
        capacity_per_instance          = optional(number, 1)
        max_use_count                  = optional(number, 100)
        update_interval                = optional(string, "1m")
        update_interval_when_expecting = optional(string, "2s")
        instance_ready_command         = optional(string, "")
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

variable "runner_gitlab" {
    description = <<-EOT
    ca_certificate = Trusted CA certificate bundle (PEM format).
    certificate = Certificate of the GitLab instance to connect to (PEM format).
    registration_token = (deprecated, This is replaced by the `registration_token` in `runner_gitlab_registration_config`.) Registration token to use to register the Runner.
    runner_version = Version of the [GitLab Runner](https://gitlab.com/gitlab-org/gitlab-runner/-/releases). Make sure that it is available for your AMI. See https://packages.gitlab.com/app/runner/gitlab-runner/search?dist=amazon%2F2023&filter=rpms&page=1&q=
    url = URL of the GitLab instance to connect to.
    url_clone = URL of the GitLab instance to clone from. Use only if the agent can’t connect to the GitLab URL.
    access_token_secure_parameter_store_name = (deprecated) The name of the SSM parameter to read the GitLab access token from. It must have the `api` scope and be pre created.
    preregistered_runner_token_ssm_parameter_name = The name of the SSM parameter to read the preregistered GitLab Runner token from.
  EOT
    type = object({
        ca_certificate                                = optional(string, "")
        certificate                                   = optional(string, "")
        registration_token                            = optional(string, "__REPLACED_BY_USER_DATA__") # deprecated, removed in 8.0.0
        runner_version                                = optional(string, "16.0.3")
        url                                           = optional(string, "")
        url_clone                                     = optional(string, "")
        access_token_secure_parameter_store_name      = optional(string, "gitlab-runner-access-token") # deprecated, removed in 8.0.0
        preregistered_runner_token_ssm_parameter_name = optional(string, "")
    })
}

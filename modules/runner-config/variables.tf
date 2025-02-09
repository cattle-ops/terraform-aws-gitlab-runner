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

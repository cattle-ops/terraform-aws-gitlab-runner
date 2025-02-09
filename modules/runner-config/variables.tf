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

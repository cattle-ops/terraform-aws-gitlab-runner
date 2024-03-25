# ----------------------------------------------------------------------------
# Terminate Instances - Input Variables
# ----------------------------------------------------------------------------
variable "environment" {
  description = "A name that identifies the environment, used as a name prefix and for tagging."
  type        = string
}

variable "name" {
  description = "The name of the Lambda function to create. The 'environment' will be prefixed to this."
  type        = string
}

variable "asg_name" {
  description = "The name of the Auto Scaling Group to attach to. The 'environment' will be prefixed to this."
  type        = string
}

variable "asg_arn" {
  description = "The ARN of the Auto Scaling Group to attach to."
  type        = string
}

variable "tags" {
  description = "Map of tags to apply to resources."
  type        = map(any)
  default     = {}
}

variable "role_permissions_boundary" {
  description = "An optional IAM permissions boundary to use when creating IAM roles."
  type        = string
  default     = null
}

variable "cloudwatch_logging_retention_in_days" {
  description = "The number of days to retain logs in CloudWatch."
  type        = number
  default     = 30
}

variable "name_iam_objects" {
  description = "The name to use for IAM resources - roles and policies."
  type        = string
  default     = ""
}

variable "name_docker_machine_runners" {
  description = "The `Name` tag of EC2 instances created by the runner agent."
  type        = string
}

variable "kms_key_id" {
  description = "KMS key id to encrypt the resources, e.g. logs, lambda environment variables, ..."
  type        = string
}

variable "enable_xray_tracing" {
  description = "Enables X-Ray for debugging and analysis"
  type        = bool
  default     = false
}

variable "graceful_terminate_enabled" {
  description = "Whether to graceful terminate is enabled."
  type        = bool
  default     = false
}

variable "graceful_terminate_timeout" {
  description = "Time in seconds to wait for lifecycle complete action before continuing termination."
  type        = number
}

variable "sqs_visibility_timeout" {
  description = "Time in seconds that a message will be invisible for after being consumed."
  type        = number
}

variable "sqs_max_receive_count" {
  description = "Number of times a message can be consumed before it's placed in the DLQ."
  type        = number
}

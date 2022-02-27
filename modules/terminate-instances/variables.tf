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

variable "lifecycle_heartbeat_timeout" {
  description = "The amount of time, in seconds, for the instances to remain in wait state."
  type        = number
  default     = 90
}

variable "name_iam_objects" {
  description = "The name to use for IAM resources - roles and policies."
  type        = string
  default     = ""
}

variable "lambda_memory_size" {
  description = "The memory size in MB to allocate to the Lambda function."
  type        = number
  default     = 128
}

variable "lambda_timeout" {
  description = "Amount of time the Lambda Function has to run in seconds."
  default     = 10
  type        = number
}
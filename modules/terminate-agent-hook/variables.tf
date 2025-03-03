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

variable "timeout" {
  description = "Timeout in seconds for the Lambda function."
  type        = number
  default     = 90
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
  description = "(optional) KMS key id to encrypt the resources, e.g. logs, lambda environment variables, ..."
  type        = string
}

variable "enable_xray_tracing" {
  description = "Enables X-Ray for debugging and analysis"
  type        = bool
  default     = false
}

variable "asg_hook_terminating_heartbeat_timeout" {
  description = "Duration in seconds the ASG should stay in the Terminating:Wait state."
  type        = number
  default     = 30

  validation {
    condition     = var.asg_hook_terminating_heartbeat_timeout >= 30 && var.asg_hook_terminating_heartbeat_timeout <= 7200
    error_message = "AWS only supports heartbeat timeout in the range of 30 to 7200."
  }
}

variable "environment_variables" {
  description = "Environment variables to set for the Lambda function. A value of `{HANDLER} is replaced with the handler value of the Lambda function."
  type        = map(string)
  default     = {}
}

variable "layer_arns" {
  description = "A list of ARNs of Lambda layers to attach to the Lambda function."
  type        = list(string)
  default     = []
}

variable "lambda_handler" {
  description = "The entry point for the Lambda function."
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "The VPC used for the runner and runner workers."
  type        = string
}

variable "subnet_id" {
  type        = string
  description = "The subnet for the lambda function."
}

variable "egress_rules" {
  description = "Map of egress rules for the Lambda function."
  type = map(object({
    from_port       = optional(number, null)
    to_port         = optional(number, null)
    protocol        = string
    description     = string
    cidr_block      = optional(string, null)
    ipv6_cidr_block = optional(string, null)
    prefix_list_id  = optional(string, null)
    security_group  = optional(string, null)
  }))
}

variable "environment" {
  description = "A name that identifies the environment, used as prefix and for tagging."
  type        = string
}

variable "cache_bucket_prefix" {
  description = "Prefix for s3 cache bucket name."
  type        = string
  default     = ""
}

variable "cache_bucket_set_random_suffix" {
  description = "Random string suffix for s3 cache bucket"
  type        = bool
  default     = false
}

variable "cache_bucket_name_include_account_id" {
  description = "Boolean to add current account ID to cache bucket name."
  type        = bool
  default     = true
}

variable "cache_bucket_versioning" {
  description = "Boolean used to enable versioning on the cache bucket, false by default."
  type        = string
  default     = "false"
}

variable "cache_expiration_days" {
  description = "Number of days before cache objects expires."
  type        = number
  default     = 1
}

variable "tags" {
  description = "Map of tags that will be added to created resources. By default resources will be tagged with name and environment."
  type        = map(string)
  default     = {}
}

variable "create_cache_bucket" {
  description = "This module is by default included in the runner module. To disable the creation of the bucket this parameter can be disabled."
  type        = bool
  default     = true
}

variable "cache_lifecycle_clear" {
  description = "Enable the rule to cleanup the cache for expired objects."
  type        = bool
  default     = true
}

variable "cache_lifecycle_prefix" {
  description = "Object key prefix identifying one or more objects to which the clean up rule applies."
  type        = string
  default     = "runner/"
}

variable "arn_format" {
  type        = string
  default     = "arn:aws"
  description = "ARN format to be used. May be changed to support deployment in GovCloud/China regions."
}

variable "name_iam_objects" {
  description = "Set the name prefix of all AWS IAM resources created by this module"
  type        = string
  default     = ""
}
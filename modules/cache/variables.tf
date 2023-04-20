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
  type        = bool
  default     = false
}

variable "cache_expiration_days" {
  description = "Number of days before cache objects expires."
  type        = number
  default     = 1
}

variable "cache_logging_bucket" {
  type        = string
  description = "S3 Bucket ID where the access logs to the cache bucket are stored."
  default     = null
}

variable "cache_logging_bucket_prefix" {
  type        = string
  description = "Prefix within the `cache_logging_bucket`."
  default     = null
}

variable "tags" {
  description = "Map of tags that will be added to created resources. By default resources will be tagged with name and environment."
  type        = map(string)
  default     = {}
}

variable "create_cache_bucket" {
  description = "(deprecated) If the cache should not be created, remove the whole module call!"
  type        = bool
  default     = null

  validation {
    condition     = anytrue([var.create_cache_bucket == null])
    error_message = "Deprecated, don't call the module when not creating a cache bucket."
  }
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

variable "kms_key_id" {
  description = "KMS key id to encrypted the resources. Ensure that your Runner/Executor has access to the KMS key."
  type        = string
  default     = ""
}

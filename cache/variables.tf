variable "environment" {
  description = "A name that identifies the environment, used as prefix and for tagging."
  type        = "string"
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

variable "tags" {
  type        = "map"
  description = "Map of tags that will be added to created resources. By default resources will be tagged with name and environment."
  default     = {}
}

variable "create_cache_bucket" {
  default = true
}

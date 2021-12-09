variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "A name that identifies the environment, will used as prefix and for tagging."
  default     = "runner-public"
  type        = string
}

variable "runner_name" {
  description = "Name of the runner, will be used in the runner config.toml"
  type        = string
  default     = "public-auto"
}

variable "gitlab_url" {
  description = "URL of the gitlab instance to connect to."
  type        = string
  default     = "https://gitlab.com"
}

variable "registration_token" {
}

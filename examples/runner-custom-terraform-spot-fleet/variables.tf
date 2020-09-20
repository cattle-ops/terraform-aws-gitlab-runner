variable "aws_region" {
  type = string
}

variable "environment" {
  type = string
}

variable "gitlab_url" {
  description = "URL of the gitlab instance to connect to."
  type        = string
}

variable "runner_token" {
  description = "Token for the runner, will be used in the runner config.toml"
  type        = string
}

variable "timezone" {
  description = "Name of the timezone that the runner will be used in."
  type        = string
  default     = "Europe/Amsterdam"
}

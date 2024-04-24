variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "A name that identifies the environment, will used as prefix and for tagging."
  default     = "ci-runners"
  type        = string
}

variable "runner_name" {
  description = "Name of the runner, will be used in the runner config.toml"
  type        = string
}

variable "gitlab_url" {
  description = "URL of the gitlab instance to connect to."
  type        = string
}

variable "preregistered_runner_token_ssm_parameter_name" {
  description = "The name of the SSM parameter to read the preregistered GitLab Runner token from."
  type        = string
}

variable "timezone" {
  description = "Timezone that will be set for the runner."
  type        = string
  default     = "Europe/Amsterdam"
}

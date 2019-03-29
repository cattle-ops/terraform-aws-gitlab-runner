variable "aws_region" {
  description = "AWS region."
  type        = "string"
  default     = "eu-west-1"
}

variable "environment" {
  description = "A name that indentifies the environment, will used as prefix and for taggin."
  type        = "string"
  default     = "runners-default"
}

variable "public_ssh_key_filename" {
  default = "generated/id_rsa.pub"
}

variable "private_ssh_key_filename" {
  default = "generated/id_rsa"
}

variable "runner_name" {
  description = "Name of the runner, will be used in the runner config.toml"
  type        = "string"
  default     = "default-auto"
}

variable "gitlab_url" {
  description = "URL of the gitlab instance to connect to."
  type        = "string"
  default     = "https://gitlab.com"
}

variable "registration_token" {}

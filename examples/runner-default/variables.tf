variable "aws_region" {
  description = "AWS region."
  type        = "string"
  default     = "eu-west-1"
}

variable "environment" {
  description = "A name that indentifies the environment, will used as prefix and for taggin."
  default     = "ci-runners"
  type        = "string"
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
}

variable "gitlab_url" {
  description = "URL of the gitlab instance to connect to."
  type        = "string"
}

variable "runner_token" {
  description = "Token for the runner, will be used in the runner config.toml"
  type        = "string"
}

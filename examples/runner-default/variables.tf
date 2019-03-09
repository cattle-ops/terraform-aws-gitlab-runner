variable "aws_region" {
  description = "AWS region."
  type        = "string"
  default     = "eu-west-1"
}

variable "environment" {
  description = "A name that identifies the environment, will used as prefix and for tagging."
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
  description = "URL of the Gitlab instance to connect to."
  type        = "string"
}

variable "runner_token" {
  description = "Token for the runner, will be used in the runner config.toml"
  type        = "string"
}

variable "key_pair_name" {
  description = "Name of the key pair to use to auth to the runner instance. Leave unspecified to auto create. Use in combination with the write_private_key var to save the key."
  type        = "string"
  default     = ""
}

variable "write_private_key" {
  description = "Boolean to control saving of the generated private ssh key to disk."
  default     = false
}

variable "image_id" {
  type = string
}

variable "subnets" {
  type = list(string)
}

variable "instance_types" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "tags" {
  type = map(string)
}

variable "spot_price" {
  type = string
}

variable "volume_size" {
  type = string
}

variable "iam_instance_profile" {
  type = string
}

variable "spot_fleet_tagging_role_arn" {
  type = string
}

# Provider variables
variable "region" {
  type = string
}

# Docker Machine variables
variable "dm_client_ip" {}
variable "dm_machine_name" {}
variable "dm_ssh_user" {}
variable "dm_ssh_port" {}
variable "dm_ssh_public_key_file" {}
variable "dm_ssh_private_key_file" {}
variable "dm_onetime_password" {}

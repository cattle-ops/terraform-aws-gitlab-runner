variable "rsa_bits" {
  description = ""
  type        = string
  default     = 4048
}

variable "public_ssh_key_filename" {
  description = "Filename (full path) for the public key."
  type        = string
  default     = "./generated/id_rsa.pub"
}

variable "private_ssh_key_filename" {
  description = "Filename (full path) for the private key."
  type        = string
  default     = "./generated/id_rsa"
}

variable "environment" {
  description = "Name of the environment (aka namespace) to ensure resources are unique."
  type        = string
}

variable "name" {
  description = "Name of the key, will be prefixed by the environment name."
  default     = null
  type        = string
}

variable "tags" {
  description = "Map of tags that will be added to created resources. By default resources will be tagged with name and environment."
  type        = map(string)
  default     = {}
}

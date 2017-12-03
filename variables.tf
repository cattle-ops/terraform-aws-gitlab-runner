variable "aws_region" {
  description = "AWS region."
  type        = "string"
}

variable "environment" {
  description = "A name that indentifies the environment, will used as prefix and for taggin."
  type        = "string"
}

variable "vpc_id" {
  description = "The VPC that is used for the instances."
  type        = "string"
}

variable "subnet_id_runners" {
  description = "Subnet used to hosts the docker-machine runners."
  type        = "string"
}

variable "subnet_id_gitlab_runner" {
  description = "Subnet used for hosting the gitlab-runner."
  type        = "string"
}

variable "instance_type" {
  description = "Instance type used for the gitlab-runner."
  type        = "string"
  default     = "t2.micro"
}

# list with amazon linux optimized images per region
# last updated on: 2017-11-19 https://aws.amazon.com/amazon-linux-ami/
variable "amazon_optimized_amis" {
  description = "AMI map per region-zone for the gitlab-runner instance AMI."
  type        = "map"

  default = {
    us-east-1      = "ami-8c1be5f6" # N. Virginia
    us-east-2      = "ami-c5062ba0" # Ohio
    us-west-1      = "ami-e689729e" # N. California
    us-west-2      = "ami-02eada62" # Oregon
    eu-west-1      = "ami-acd005d5" # Ireland
    eu-west-2      = "ami-1a7f6d7e" # London
    eu-central-1   = "ami-c7ee5ca8" # Frankfurt
    ap-northeast-1 = "ami-0797ea64" # Tokyo
    ap-northeast-2 = "ami-9bec36f5" # Seoel
    ap-southeast-1 = "ami-2a69be4c" # Singapore
    ap-southeast-2 = "ami-8536d6e7" # Sydney
    ap-south-1     = "ami-4fc58420" # Mumbai
    ca-central-1   = "ami-fd55ec99" # Canada
  }
}

variable "ssh_key_file_pub" {
  description = "File contians the public key used for the gitlab-runner."
  type        = "string"
}

variable "docker_machine_instance_type" {
  description = "Instance type used for the instances hosting docker-machine."
  default     = "m3.large"
}

variable "docker_machine_spot_price_bid" {
  description = "Spot price bid."
  default     = "0.03"
}

variable "runners_name" {
  description = "Name of the runner, will be used in the runner config.toml"
  type        = "string"
}

variable "runners_gitlab_url" {
  description = "URL of the gitlab instance to connect to."
  type        = "string"
}

variable "runners_token" {
  description = "Token for the runner, will be used in the runner config.toml"
  type        = "string"
}

variable "runners_limit" {
  description = "Limit for the runners, will be used in the runner config.toml"
  default     = 1
}

variable "runners_concurrent" {
  description = "Concurrent value for the runners, will be used in the runner config.toml"
  default     = 10
}

variable "runners_idle_time" {
  description = "Idle time of the runners, will be used in the runner config.toml"
  default     = 600
}

variable "runners_idle_count" {
  description = "Idle count of the runners, will be used in the runner config.toml"
  default     = 0
}

variable "runners_privilled" {
  description = "Runners will run in privilled mode, will be used in the runner config.toml"
  default     = true
}

variable "docker_machine_user" {
  description = "User name for the user to create spot instances to host docker-machine."
  type        = "string"
  default     = "docker-machine"
}

variable "cache_user" {
  description = "User name of the user to create to write and read to the s3 cache."
  type        = "string"
  default     = "cache_user"
}

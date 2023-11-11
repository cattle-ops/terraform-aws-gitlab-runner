data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_subnet" "runners" {
  id = var.subnet_id
}

data "aws_availability_zone" "runners" {
  name = data.aws_subnet.runners.availability_zone
}

data "aws_ami" "runner" {
  most_recent = "true"

  dynamic "filter" {
    for_each = var.runner_ami_filter
    content {
      name   = filter.key
      values = filter.value
    }
  }

  owners = var.runner_ami_owners
}

data "aws_ami" "docker-machine" {
  count = var.runner_worker.type == "docker+machine" ? 1 : 0

  most_recent = "true"

  dynamic "filter" {
    for_each = var.runner_worker_docker_machine_ami_filter
    content {
      name   = filter.key
      values = filter.value
    }
  }

  owners = var.runner_worker_docker_machine_ami_owners
}

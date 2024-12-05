data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_subnet" "runners" {
  id = var.subnet_id
}

data "aws_availability_zone" "runners" {
  name = data.aws_subnet.runners.availability_zone
}

data "aws_ami" "runner_by_filter" {
  count = length(var.runner_ami_id) > 0 ? 0 : 1

  owners      = var.runner_ami_owners
  most_recent = "true"

  dynamic "filter" {
    for_each = var.runner_ami_filter

    content {
      name   = filter.key
      values = filter.value
    }
  }
}

data "aws_ami" "docker_machine_by_filter" {
  count = var.runner_worker.type == "docker+machine" && length(var.runner_worker_docker_machine_ami_id) == 0 ? 1 : 0

  owners      = var.runner_worker_docker_machine_ami_owners
  most_recent = "true"

  dynamic "filter" {
    for_each = var.runner_worker_docker_machine_ami_filter

    content {
      name   = filter.key
      values = filter.value
    }
  }
}

data "aws_ami" "docker_autoscaler_by_filter" {
  count = var.runner_worker.type == "docker-autoscaler" && length(var.runner_worker_docker_autoscaler_ami_id) == 0 ? 1 : 0

  owners      = var.runner_worker_docker_autoscaler_ami_owners
  most_recent = "true"

  dynamic "filter" {
    for_each = var.runner_worker_docker_autoscaler_ami_filter

    content {
      name   = filter.key
      values = filter.value
    }
  }
}

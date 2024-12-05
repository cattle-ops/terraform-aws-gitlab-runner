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
  id = length(var.runner_ami_id) > 0 ? var.runner_ami_id : null
  owners = length(var.runner_ami_id) > 0 ? var.runner_ami_owners : null
  most_recent = "true"

  dynamic "filter" {
    for_each = length(var.runner_ami_id) > 0 ? [] : var.runner_ami_filter

    content {
      name   = filter.key
      values = filter.value
    }
  }
}

data "aws_ami" "docker_machine" {
  count = var.runner_worker.type == "docker+machine" ? 1 : 0

  id = length(var.runner_worker_docker_machine_ami_id) > 0 ? var.runner_worker_docker_machine_ami_id : null
  owners = length(var.runner_worker_docker_machine_ami_id) > 0 ? var.runner_worker_docker_machine_ami_owners : null
  most_recent = "true"

  dynamic "filter" {
    for_each = length(var.runner_worker_docker_machine_ami_id) > 0 ? [] : var.runner_worker_docker_machine_ami_filter

    content {
      name   = filter.key
      values = filter.value
    }
  }
}

data "aws_ami" "docker-autoscaler" {
  count = var.runner_worker.type == "docker-autoscaler" ? 1 : 0

  id = length(var.runner_worker_docker_autoscaler_ami_id) > 0 ? var.runner_worker_docker_autoscaler_ami_id : null
  owners = length(var.runner_worker_docker_autoscaler_ami_id) > 0 ? var.runner_worker_docker_autoscaler_ami_owners : null
  most_recent = "true"

  dynamic "filter" {
    for_each = length(var.runner_worker_docker_autoscaler_ami_id) > 0 ? [] : var.runner_worker_docker_autoscaler_ami_filter

    content {
      name   = filter.key
      values = filter.value
    }
  }
}

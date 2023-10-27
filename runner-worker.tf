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

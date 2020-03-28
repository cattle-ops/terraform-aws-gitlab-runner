########################################
## Validation                         ##
########################################

# prevent allow from world through cidr ranges while security_group_ids are used
# This statement should fail during the plan phase, resulting in an error.
# https://github.com/hashicorp/terraform/issues/15469#issuecomment-444876784
resource "null_resource" "fail_if_security_group_ids_are_set_and_cidr_blocks_allow_all" {
  count = length(var.gitlab_runner_security_group_ids) > 0 && var.gitlab_runner_ssh_cidr_blocks == ["0.0.0.0/0"] ? 1 : 0

  provisioner "local-exec" {
    command     = "false"
    interpreter = ["bash", "-c"]
  }
}

########################################
## Gitlab-runner agent security group ##
########################################

resource "aws_security_group" "runner" {
  name_prefix = "${var.environment}-security-group"
  vpc_id      = var.vpc_id
  description = "A security group containing gitlab-runner agent instances"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    {
      "Name" = format("%s", local.name_sg)
    },
  )
}

########################################
## CIDR ranges to runner agent        ##
########################################

# Allow SSH traffic from allowed cidr blocks to gitlab-runner agent instances
resource "aws_security_group_rule" "runner_ssh" {
  count = length(var.gitlab_runner_ssh_cidr_blocks) > 0 && var.enable_gitlab_runner_ssh_access ? length(var.gitlab_runner_ssh_cidr_blocks) : 0

  type      = "ingress"
  from_port = 22
  to_port   = 22
  protocol  = "tcp"

  cidr_blocks       = [element(var.gitlab_runner_ssh_cidr_blocks, count.index)]
  security_group_id = aws_security_group.runner.id

  description = format(
    "Allow SSH traffic from %s to gitlab-runner agent instances in group %s",
    element(var.gitlab_runner_ssh_cidr_blocks, count.index),
    aws_security_group.runner.name
  )
}

# Allow ICMP traffic from allowed cidr blocks to gitlab-runner agent instances
resource "aws_security_group_rule" "runner_ping" {
  count = length(var.gitlab_runner_ssh_cidr_blocks) > 0 && var.enable_ping ? length(var.gitlab_runner_ssh_cidr_blocks) : 0

  type      = "ingress"
  from_port = -1
  to_port   = -1
  protocol  = "icmp"

  cidr_blocks       = [element(var.gitlab_runner_ssh_cidr_blocks, count.index)]
  security_group_id = aws_security_group.runner.id

  description = format(
    "Allow ICMP traffic from %s to gitlab-runner agent instances in group %s",
    element(var.gitlab_runner_ssh_cidr_blocks, count.index),
    aws_security_group.runner.name
  )

}

########################################
## Security group IDs to runner agent ##
########################################

# Allow SSH traffic from allowed security group IDs to gitlab-runner agent instances
resource "aws_security_group_rule" "runner_ssh_group" {
  count = length(var.gitlab_runner_security_group_ids) > 0 && var.enable_gitlab_runner_ssh_access ? length(var.gitlab_runner_security_group_ids) : 1

  type      = "ingress"
  from_port = 22
  to_port   = 22
  protocol  = "tcp"

  source_security_group_id = element(var.gitlab_runner_security_group_ids, count.index)
  security_group_id        = aws_security_group.runner.id

  description = format(
    "Allow SSH traffic from %s to gitlab-runner agent instances in group %s",
    element(var.gitlab_runner_security_group_ids, count.index),
    aws_security_group.runner.name
  )
}

# Allow ICMP traffic from allowed security group IDs to gitlab-runner agent instances
resource "aws_security_group_rule" "runner_ping_group" {
  count = length(var.gitlab_runner_security_group_ids) > 0 && var.enable_ping ? length(var.gitlab_runner_security_group_ids) : 0

  type      = "ingress"
  from_port = -1
  to_port   = -1
  protocol  = "icmp"

  source_security_group_id = element(var.gitlab_runner_security_group_ids, count.index)
  security_group_id        = aws_security_group.runner.id

  description = format(
    "Allow ICMP traffic from %s to gitlab-runner agent instances in group %s",
    element(var.gitlab_runner_security_group_ids, count.index),
    aws_security_group.runner.name
  )
}

########################################
## Docker-machine security group      ##
########################################

resource "aws_security_group" "docker_machine" {
  name_prefix = "${var.environment}-docker-machine"
  vpc_id      = var.vpc_id
  description = "A security group containing docker-machine instances"

  tags = merge(
    local.tags,
    {
      "Name" = format("%s", local.name_sg)
    },
  )
}

########################################
## Runner agent to docker-machine     ##
########################################

# Allow docker-machine traffic from gitlab-runner agent instances to docker-machine instances
resource "aws_security_group_rule" "docker_machine_docker_runner" {
  type      = "ingress"
  from_port = 2376
  to_port   = 2376
  protocol  = "tcp"

  source_security_group_id = aws_security_group.runner.id
  security_group_id        = aws_security_group.docker_machine.id

  description = format(
    "Allow docker-machine traffic from group %s to docker-machine instances in group %s",
    aws_security_group.runner.name,
    aws_security_group.docker_machine.name
  )
}

########################################
## Security groups to docker-machine  ##
########################################

locals {
  security_groups_ssh = var.enable_gitlab_runner_ssh_access && length(var.gitlab_runner_security_group_ids) > 0 ? concat(var.gitlab_runner_security_group_ids, [aws_security_group.runner.id]) : [aws_security_group.runner.id]

  security_groups_ping = var.enable_ping && length(var.gitlab_runner_security_group_ids) > 0 ? concat(var.gitlab_runner_security_group_ids, [aws_security_group.runner.id]) : []
}

# Allow SSH traffic from gitlab-runner agent instances and security group IDs to docker-machine instances
resource "aws_security_group_rule" "docker_machine_ssh_runner" {
  count = length(local.security_groups_ssh)

  type      = "ingress"
  from_port = 22
  to_port   = 22
  protocol  = "tcp"

  source_security_group_id = element(var.gitlab_runner_security_group_ids, count.index)
  security_group_id        = aws_security_group.docker_machine.id

  description = format(
    "Allow SSH traffic from %s to docker-machine instances in group %s on port 22",
    element(var.gitlab_runner_security_group_ids, count.index),
    aws_security_group.docker_machine.name
  )
}

# Allow ICMP traffic from gitlab-runner agent instances and security group IDs to docker-machine instances
resource "aws_security_group_rule" "docker_machine_ping_runner" {
  count = length(local.security_groups_ping)

  type      = "ingress"
  from_port = -1
  to_port   = -1
  protocol  = "icmp"

  source_security_group_id = element(var.gitlab_runner_security_group_ids, count.index)
  security_group_id        = aws_security_group.docker_machine.id

  description = format(
    "Allow ICMP traffic from %s to docker-machine instances in group %s",
    element(var.gitlab_runner_security_group_ids, count.index),
    aws_security_group.docker_machine.name
  )
}

########################################
## Docker-machine instances to self   ##
########################################

# Allow docker-machine traffic from docker-machine instances to docker-machine instances on port 2376
resource "aws_security_group_rule" "docker_machine_docker_self" {
  type      = "ingress"
  from_port = 2376
  to_port   = 2376
  protocol  = "tcp"
  self      = true

  security_group_id = aws_security_group.docker_machine.id

  description = format(
    "Allow docker-machine traffic within group %s on port 2376",
    aws_security_group.docker_machine.name,
  )
}

# Allow SSH traffic from docker-machine instances to docker-machine instances on port 22
resource "aws_security_group_rule" "docker_machine_ssh_self" {
  type      = "ingress"
  from_port = 22
  to_port   = 22
  protocol  = "tcp"
  self      = true

  security_group_id = aws_security_group.docker_machine.id

  description = format(
    "Allow SSH traffic within group %s on port 22",
    aws_security_group.docker_machine.name,
  )
}

# Allow ICMP traffic from docker-machine instances to docker-machine instances
resource "aws_security_group_rule" "docker_machine_ping_self" {
  count     = var.enable_ping ? 1 : 0
  type      = "ingress"
  from_port = -1
  to_port   = -1
  protocol  = "icmp"
  self      = true

  security_group_id = aws_security_group.docker_machine.id

  description = format(
    "Allow ICMP traffic within group %s",
    aws_security_group.docker_machine.name,
  )
}

########################################
## Egress Security rules              ##
########################################

# Allow egress traffic from docker-machine instances
resource "aws_security_group_rule" "out_all" {
  type        = "egress"
  from_port   = 0
  to_port     = 65535
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.docker_machine.id

  description = format(
    "Allow egress traffic for group %s",
    aws_security_group.docker_machine.name,
  )
}

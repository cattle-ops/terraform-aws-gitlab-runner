########################################
## Gitlab-runner agent security group ##
########################################

resource "aws_security_group" "runner" {
  name_prefix = local.name_sg
  vpc_id      = var.vpc_id
  description = var.gitlab_runner_security_group_description

  dynamic "egress" {
    for_each = var.gitlab_runner_egress_rules
    iterator = each

    content {
      cidr_blocks      = each.value.cidr_blocks
      ipv6_cidr_blocks = each.value.ipv6_cidr_blocks
      prefix_list_ids  = each.value.prefix_list_ids
      from_port        = each.value.from_port
      protocol         = each.value.protocol
      security_groups  = each.value.security_groups
      self             = each.value.self
      to_port          = each.value.to_port
      description      = each.value.description
    }
  }

  tags = merge(
    local.tags,
    {
      "Name" = format("%s", local.name_sg)
    },
  )
}

########################################
## Security group IDs to runner agent ##
########################################

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
  name_prefix = "${local.name_sg}-docker-machine"
  vpc_id      = var.vpc_id
  description = var.docker_machine_security_group_description

  dynamic "egress" {
    for_each = var.docker_machine_egress_rules
    iterator = each

    content {
      cidr_blocks      = each.value.cidr_blocks
      ipv6_cidr_blocks = each.value.ipv6_cidr_blocks
      prefix_list_ids  = each.value.prefix_list_ids
      from_port        = each.value.from_port
      protocol         = each.value.protocol
      security_groups  = each.value.security_groups
      self             = each.value.self
      to_port          = each.value.to_port
      description      = each.value.description
    }
  }

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

# Combine runner security group id and additional security group IDs
locals {
  # Only include runner security group id and addtional if ping is enabled
  security_groups_ping = var.enable_ping && length(var.gitlab_runner_security_group_ids) > 0 ? concat(var.gitlab_runner_security_group_ids, [aws_security_group.runner.id]) : []
}

# Allow SSH traffic from gitlab-runner agent instances and security group IDs to docker-machine instances
resource "aws_security_group_rule" "docker_machine_ssh_runner" {
  type      = "ingress"
  from_port = 22
  to_port   = 22
  protocol  = "tcp"

  source_security_group_id = aws_security_group.runner.id
  security_group_id        = aws_security_group.docker_machine.id

  description = format(
    "Allow SSH traffic from %s to docker-machine instances in group %s on port 22",
    aws_security_group.runner.id,
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

  source_security_group_id = element(local.security_groups_ping, count.index)
  security_group_id        = aws_security_group.docker_machine.id

  description = format(
    "Allow ICMP traffic from %s to docker-machine instances in group %s",
    element(local.security_groups_ping, count.index),
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

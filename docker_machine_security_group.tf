# Combine runner security group id and additional security group IDs
locals {
  # Only include runner security group id and additional if ping is enabled
  security_groups_ping = var.runner_networking.allow_incoming_ping && length(var.runner_networking.allow_incoming_ping_security_group_ids) > 0 ? concat(var.runner_networking.allow_incoming_ping_security_group_ids, [aws_security_group.runner.id]) : []
}

resource "aws_security_group" "docker_machine" {
  # checkov:skip=CKV2_AWS_5:Security group is used within an template and assigned to the docker machines
  count = var.runner_worker.type == "docker+machine" ? 1 : 0

  name_prefix = "${local.name_sg}-docker-machine"
  vpc_id      = var.vpc_id
  description = var.runner_worker_docker_machine_security_group_description

  tags = merge(
    local.tags,
    {
      "Name" = format("%s", local.name_sg)
    },
  )
}

resource "aws_vpc_security_group_ingress_rule" "docker_machine" {
  for_each = var.runner_worker.type == "docker+machine" ? var.runner_worker_ingress_rules : {}

  security_group_id = aws_security_group.docker_machine[0].id

  from_port   = each.value.from_port
  to_port     = each.value.to_port
  ip_protocol = each.value.protocol

  description                  = each.value.description
  prefix_list_id               = each.value.prefix_list_id
  referenced_security_group_id = each.value.security_group
  cidr_ipv4                    = each.value.cidr_block
  cidr_ipv6                    = each.value.ipv6_cidr_block

  tags = local.tags
}

resource "aws_vpc_security_group_egress_rule" "docker_machine" {
  for_each = var.runner_worker.type == "docker+machine" ? var.runner_worker_egress_rules : {}

  security_group_id = aws_security_group.docker_machine[0].id

  from_port   = each.value.from_port
  to_port     = each.value.to_port
  ip_protocol = each.value.protocol

  description                  = each.value.description
  prefix_list_id               = each.value.prefix_list_id
  referenced_security_group_id = each.value.security_group
  cidr_ipv4                    = each.value.cidr_block
  cidr_ipv6                    = each.value.ipv6_cidr_block

  tags = local.tags
}

########################################
## Runner agent to docker-machine     ##
########################################

# Allow docker-machine traffic from gitlab-runner agent instances to docker-machine instances
resource "aws_vpc_security_group_ingress_rule" "docker_machine_docker_runner" {
  count = var.runner_worker.type == "docker+machine" ? 1 : 0

  security_group_id = aws_security_group.docker_machine[0].id

  from_port   = 2376
  to_port     = 2376
  ip_protocol = "tcp"

  referenced_security_group_id = aws_security_group.runner.id

  description = format(
    "Allow docker-machine traffic from group %s to docker-machine instances in group %s",
    aws_security_group.runner.name,
    aws_security_group.docker_machine[0].name
  )

  tags = local.tags
}

# Allow SSH traffic from gitlab-runner agent instances and security group IDs to docker-machine instances
resource "aws_vpc_security_group_ingress_rule" "docker_machine_ssh_runner" {
  count = var.runner_worker.type == "docker+machine" ? 1 : 0

  security_group_id = aws_security_group.docker_machine[0].id

  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"

  referenced_security_group_id = aws_security_group.runner.id

  description = format(
    "Allow SSH traffic from %s to docker-machine instances in group %s on port 22",
    aws_security_group.runner.id,
    aws_security_group.docker_machine[0].name
  )

  tags = local.tags
}

# Allow ICMP traffic from gitlab-runner agent instances and security group IDs to docker-machine instances
resource "aws_vpc_security_group_ingress_rule" "docker_machine_ping_runner" {
  # checkov:skip=CKV_AWS_277:False positive. ICMP traffic has no ports.
  count = var.runner_worker.type == "docker+machine" ? length(local.security_groups_ping) : 0

  security_group_id = aws_security_group.docker_machine[0].id

  from_port   = -1
  to_port     = -1
  ip_protocol = "icmp"

  referenced_security_group_id = element(local.security_groups_ping, count.index)

  description = format(
    "Allow ICMP traffic from %s to docker-machine instances in group %s",
    element(local.security_groups_ping, count.index),
    aws_security_group.docker_machine[0].name
  )

  tags = local.tags
}

########################################
## Docker-machine instances to self   ##
########################################

# Allow docker-machine traffic from docker-machine instances to docker-machine instances on port 2376
resource "aws_vpc_security_group_ingress_rule" "docker_machine_docker_self" {
  count = var.runner_worker.type == "docker+machine" ? 1 : 0

  security_group_id = aws_security_group.docker_machine[0].id

  from_port   = 2376
  to_port     = 2376
  ip_protocol = "tcp"

  referenced_security_group_id = aws_security_group.docker_machine[0].id

  description = format(
    "Allow docker-machine traffic within group %s on port 2376",
    aws_security_group.docker_machine[0].name,
  )

  tags = local.tags
}

# Allow SSH traffic from docker-machine instances to docker-machine instances on port 22
resource "aws_vpc_security_group_ingress_rule" "docker_machine_ssh_self" {
  count = var.runner_worker.type == "docker+machine" ? 1 : 0

  security_group_id = aws_security_group.docker_machine[0].id

  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.docker_machine[0].id

  description = format(
    "Allow SSH traffic within group %s on port 22",
    aws_security_group.docker_machine[0].name,
  )

  tags = local.tags
}

# Allow ICMP traffic from docker-machine instances to docker-machine instances
resource "aws_vpc_security_group_ingress_rule" "docker_machine_ping_self" {
  # checkov:skip=CKV_AWS_277:False positive. ICMP traffic has no ports.
  count = (var.runner_worker.type == "docker+machine" && var.runner_networking.allow_incoming_ping) ? 1 : 0

  security_group_id = aws_security_group.docker_machine[0].id

  from_port                    = -1
  to_port                      = -1
  ip_protocol                  = "icmp"
  referenced_security_group_id = aws_security_group.docker_machine[0].id

  description = format(
    "Allow ICMP traffic within group %s",
    aws_security_group.docker_machine[0].name,
  )

  tags = local.tags
}

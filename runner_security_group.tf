########################################
## Gitlab-runner agent security group ##
########################################

resource "aws_security_group" "runner" {
  # checkov:skip=CKV2_AWS_5:False positive. Security group is used in a launch template network interface section.
  name_prefix = local.name_sg
  vpc_id      = var.vpc_id
  description = var.runner_networking.security_group_description

  tags = merge(
    local.tags,
    {
      "Name" = format("%s", local.name_sg)
    },
  )
}

resource "aws_vpc_security_group_ingress_rule" "runner" {
  for_each = var.runner_ingress_rules

  security_group_id = aws_security_group.runner.id

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

resource "aws_vpc_security_group_egress_rule" "runner" {
  for_each = var.runner_egress_rules

  security_group_id = aws_security_group.runner.id

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

resource "aws_vpc_security_group_egress_rule" "runner_manager_to_docker_autoscaler_egress" {
  count = var.runner_worker.type == "docker-autoscaler" ? 1 : 0

  security_group_id = aws_security_group.runner.id

  ip_protocol                  = "-1"
  description                  = "Allow ALL Egress traffic between Runner Manager and Docker-autoscaler workers security group"
  referenced_security_group_id = aws_security_group.docker_autoscaler[0].id

  tags = local.tags
}

resource "aws_vpc_security_group_egress_rule" "runner_manager_to_docker_machine_egress" {
  count = var.runner_worker.type == "docker+machine" ? 1 : 0

  security_group_id = aws_security_group.runner.id

  ip_protocol                  = "-1"
  description                  = "Allow ALL Egress traffic between Runner Manager and Docker-machine workers security group"
  referenced_security_group_id = aws_security_group.docker_machine[0].id

  tags = local.tags
}

########################################
## Security group IDs to runner agent ##
########################################

# Allow ICMP traffic from allowed security group IDs to gitlab-runner agent instances
resource "aws_vpc_security_group_ingress_rule" "runner_ping_group" {
  # checkov:skip=CKV_AWS_277:False positive. ICMP traffic has no ports.
  count = length(var.runner_networking.allow_incoming_ping_security_group_ids) > 0 && var.runner_networking.allow_incoming_ping ? length(var.runner_networking.allow_incoming_ping_security_group_ids) : 0

  from_port   = -1
  to_port     = -1
  ip_protocol = "icmp"

  referenced_security_group_id = element(var.runner_networking.allow_incoming_ping_security_group_ids, count.index)
  security_group_id            = aws_security_group.runner.id

  description = format(
    "Allow ICMP traffic from %s to gitlab-runner agent instances in group %s",
    element(var.runner_networking.allow_incoming_ping_security_group_ids, count.index),
    aws_security_group.runner.name
  )
}

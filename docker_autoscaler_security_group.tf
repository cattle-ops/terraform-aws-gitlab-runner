resource "aws_security_group" "docker_autoscaler" {
  count       = var.runner_worker.type == "docker-autoscaler" ? 1 : 0
  name_prefix = "${local.name_sg}-docker-autoscaler"
  vpc_id      = var.vpc_id
  description = "Docker-autoscaler security group"

  tags = merge(
    local.tags,
    {
      "Name" = format("%s", local.name_sg)
    },
  )
}

# Ingress rules
resource "aws_vpc_security_group_ingress_rule" "docker_autoscaler_ingress" {
  for_each = var.runner_worker.type == "docker-autoscaler" ? var.runner_worker_ingress_rules : {}

  security_group_id = aws_security_group.docker_autoscaler[0].id

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

resource "aws_vpc_security_group_ingress_rule" "docker_autoscaler_internal_traffic" {
  count = var.runner_worker.type == "docker-autoscaler" ? 1 : 0

  security_group_id            = aws_security_group.docker_autoscaler[0].id
  from_port                    = -1
  to_port                      = -1
  ip_protocol                  = "-1"
  description                  = "Allow ALL Ingress traffic between Runner Manager and Docker-autoscaler workers security group"
  referenced_security_group_id = aws_security_group.runner.id

  tags = local.tags
}

# Egress rules
resource "aws_vpc_security_group_egress_rule" "docker_autoscaler_egress" {
  for_each = var.runner_worker.type == "docker-autoscaler" ? var.runner_worker_egress_rules : {}

  security_group_id = aws_security_group.docker_autoscaler[0].id

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

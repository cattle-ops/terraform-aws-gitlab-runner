#
# This file is responsible for creating the resources needed to run the docker autoscaler plugin from GitLab. It replaces the
# outdated docker+machine driver. The docker+machine driver is a legacy driver that is no longer maintained by GitLab.
#

########################################
###### Security Group and SG rules #####
########################################

# Base security group
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
  for_each = var.runner_worker.type == "docker-autoscaler" ? var.runner_worker_docker_autoscaler_ingress_rules : {}

  security_group_id = aws_security_group.docker_autoscaler[0].id

  from_port   = each.value.from_port
  to_port     = each.value.to_port
  ip_protocol = each.value.protocol

  description                  = each.value.description
  prefix_list_id               = each.value.prefix_list_id
  referenced_security_group_id = each.value.security_group
  cidr_ipv4                    = each.value.cidr_block
  cidr_ipv6                    = each.value.ipv6_cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "docker_autoscaler_internal_traffic" {
  count = var.runner_worker.type == "docker-autoscaler" ? 1 : 0

  security_group_id            = aws_security_group.docker_autoscaler[0].id
  from_port                    = 0
  to_port                      = 0
  ip_protocol                  = "-1"
  description                  = "Allow ALL Ingress traffic between Runner Manager and Docker-autoscaler workers security group"
  referenced_security_group_id = aws_security_group.runner.id
}

# Egress rules
resource "aws_vpc_security_group_egress_rule" "docker_autoscaler_egress" {
  for_each = var.runner_worker.type == "docker-autoscaler" ? var.runner_worker_docker_autoscaler_egress_rules : {}

  security_group_id = aws_security_group.docker_autoscaler[0].id

  from_port   = each.value.from_port
  to_port     = each.value.to_port
  ip_protocol = each.value.protocol

  description                  = each.value.description
  prefix_list_id               = each.value.prefix_list_id
  referenced_security_group_id = each.value.security_group
  cidr_ipv4                    = each.value.cidr_block
  cidr_ipv6                    = each.value.ipv6_cidr_block
}

####################################
###### Launch template Workers #####
####################################
resource "aws_launch_template" "this" {
  count = var.runner_worker.type == "docker-autoscaler" ? 1 : 0

  name          = "${local.name_runner_agent_instance}-worker-launch-template"
  user_data     = base64gzip(var.runner_worker_docker_autoscaler_instance.start_script)
  image_id      = length(var.runner_worker_docker_autoscaler_ami_id) > 0 ? var.runner_worker_docker_autoscaler_ami_id : data.aws_ami.docker_autoscaler_by_filter[0].id
  instance_type = var.runner_worker_docker_autoscaler_asg.types[0]
  key_name      = aws_key_pair.autoscaler[0].key_name
  ebs_optimized = var.runner_worker_docker_autoscaler_instance.ebs_optimized

  monitoring {
    enabled = var.runner_worker_docker_autoscaler_instance.monitoring
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.docker_autoscaler[0].name
  }

  network_interfaces {
    security_groups             = [aws_security_group.docker_autoscaler[0].id]
    associate_public_ip_address = !var.runner_worker_docker_autoscaler_instance.private_address_only
  }

  block_device_mappings {
    device_name = var.runner_worker_docker_autoscaler_instance.root_device_name

    ebs {
      volume_size = var.runner_worker_docker_autoscaler_instance.root_size
      volume_type = var.runner_worker_docker_autoscaler_instance.volume_type
      iops        = contains(["gp3", "io1", "io2"], var.runner_worker_docker_autoscaler_instance.volume_type) ? var.runner_worker_docker_autoscaler_instance.volume_iops : null
      throughput  = var.runner_worker_docker_autoscaler_instance.volume_type == "gp3" ? var.runner_worker_docker_autoscaler_instance.volume_throughput : null
      encrypted   = true
      kms_key_id  = local.kms_key_arn
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = local.tags
  }
  tag_specifications {
    resource_type = "volume"
    tags          = local.tags
  }
  tag_specifications {
    resource_type = "network-interface"
    tags          = local.tags
  }

  tags = local.tags

  metadata_options {
    http_tokens                 = var.runner_worker_docker_autoscaler_instance.http_tokens
    http_put_response_hop_limit = var.runner_worker_docker_autoscaler_instance.http_put_response_hop_limit
    instance_metadata_tags      = "enabled"
  }

  lifecycle {
    create_before_destroy = true
  }
}

#########################################
# Autoscaling group with launch template
#########################################
# false positive, tags are created with "dynamic" block
# kics-scan ignore-line
resource "aws_autoscaling_group" "autoscaler" {
  count = var.runner_worker.type == "docker-autoscaler" ? 1 : 0

  name                  = "${local.name_runner_agent_instance}-asg"
  capacity_rebalance    = false
  protect_from_scale_in = true

  dynamic "launch_template" {
    for_each = var.runner_worker_docker_autoscaler_asg.enable_mixed_instances_policy ? [] : [1]
    content {
      id      = aws_launch_template.this[0].id
      version = aws_launch_template.this[0].latest_version
    }
  }

  dynamic "mixed_instances_policy" {
    for_each = var.runner_worker_docker_autoscaler_asg.enable_mixed_instances_policy ? [1] : []

    content {
      instances_distribution {
        on_demand_base_capacity                  = var.runner_worker_docker_autoscaler_asg.on_demand_base_capacity
        on_demand_percentage_above_base_capacity = var.runner_worker_docker_autoscaler_asg.on_demand_percentage_above_base_capacity
        spot_allocation_strategy                 = var.runner_worker_docker_autoscaler_asg.spot_allocation_strategy
        spot_instance_pools                      = var.runner_worker_docker_autoscaler_asg.spot_instance_pools
      }
      launch_template {
        launch_template_specification {
          launch_template_id = aws_launch_template.this[0].id
          version            = aws_launch_template.this[0].latest_version
        }
        dynamic "override" {
          for_each = var.runner_worker_docker_autoscaler_asg.types
          content {
            instance_type = override.value
          }
        }
      }
    }
  }

  dynamic "instance_refresh" {
    for_each = var.runner_worker_docker_autoscaler_asg.upgrade_strategy == "rolling" ? [1] : []
    content {
      strategy = "Rolling"
      preferences {
        min_healthy_percentage = var.runner_worker_docker_autoscaler_asg.instance_refresh_min_healthy_percentage
      }
      triggers = var.runner_worker_docker_autoscaler_asg.instance_refresh_triggers
    }
  }

  vpc_zone_identifier       = var.runner_worker_docker_autoscaler_asg.subnet_ids
  max_size                  = var.runner_worker.max_jobs
  min_size                  = 0
  desired_capacity          = 0 # managed by the fleeting plugin
  health_check_grace_period = var.runner_worker_docker_autoscaler_asg.health_check_grace_period
  health_check_type         = var.runner_worker_docker_autoscaler_asg.health_check_type
  force_delete              = true
  enabled_metrics           = var.runner_worker_docker_autoscaler_asg.enabled_metrics

  dynamic "tag" {
    for_each = local.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    # do not change these values as we would immediately scale up/down, which is not wanted
    ignore_changes = [
      desired_capacity,
      min_size,
      max_size
    ]
  }
}

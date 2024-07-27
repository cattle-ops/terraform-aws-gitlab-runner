#
# This file is responsible for creating the resources needed to run the docker autoscaler plugin from GitLab. It replaces the
# outdated docker+machine driver. The docker+machine driver is a legacy driver that is no longer maintained by GitLab.
#

resource "aws_security_group" "docker_autoscaler" {
  count = var.runner_worker.type == "docker-autoscaler" ? 1 : 0

  description = "Docker autoscaler security group"
  vpc_id      = var.vpc_id
  name        = "${local.name_sg}-docker-autoscaler"

  tags = merge(
    local.tags,
    {
      "Name" = format("%s", local.name_sg)
    },
  )
}

resource "aws_security_group_rule" "autoscaler_egress" {
  count = var.runner_worker.type == "docker-autoscaler" ? 1 : 0

  description       = "All egress traffic docker autoscaler"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = join("", aws_security_group.docker_autoscaler[*].id)
}

resource "aws_security_group_rule" "autoscaler_ingress" {
  count = var.runner_worker.type == "docker-autoscaler" ? 1 : 0

  description              = "All ingress traffic from runner security group"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.runner.id
  security_group_id        = join("", aws_security_group.docker_autoscaler[*].id)
}

resource "aws_security_group_rule" "extra_autoscaler_ingress" {
  count = var.runner_worker.type == "docker-autoscaler" ? length(var.runner_worker_docker_autoscaler_asg.sg_ingresses) : 0

  description       = var.runner_worker_docker_autoscaler_asg.sg_ingresses[count.index].description
  type              = "ingress"
  from_port         = var.runner_worker_docker_autoscaler_asg.sg_ingresses[count.index].from_port
  to_port           = var.runner_worker_docker_autoscaler_asg.sg_ingresses[count.index].to_port
  protocol          = var.runner_worker_docker_autoscaler_asg.sg_ingresses[count.index].protocol
  cidr_blocks       = var.runner_worker_docker_autoscaler_asg.sg_ingresses[count.index].cidr_blocks
  security_group_id = join("", aws_security_group.docker_autoscaler[*].id)
}

####################################
###### Launch template Workers #####
####################################
resource "aws_launch_template" "this" {
  count = var.runner_worker.type == "docker-autoscaler" ? 1 : 0

  name          = "${local.name_runner_agent_instance}-worker-launch-template"
  user_data     = base64gzip(var.runner_worker_docker_autoscaler_asg.start_script)
  image_id      = data.aws_ami.docker-autoscaler[0].id
  instance_type = var.runner_worker_docker_autoscaler_asg.types[0]
  key_name      = aws_key_pair.autoscaler[0].key_name
  ebs_optimized = var.runner_worker_docker_autoscaler_asg.ebs_optimized

  monitoring {
    enabled = var.runner_worker_docker_autoscaler_asg.monitoring
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.docker_autoscaler[0].name
  }

  network_interfaces {
    security_groups             = [aws_security_group.docker_autoscaler[0].id]
    associate_public_ip_address = !var.runner_worker_docker_autoscaler_asg.private_address_only
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = var.runner_worker_docker_autoscaler_asg.root_size
      volume_type = var.runner_worker_docker_autoscaler_asg.volume_type
      iops        = contains(["gp3", "io1", "io2"], var.runner_worker_docker_autoscaler_asg.volume_type) ? var.runner_worker_docker_autoscaler_asg.volume_iops : null
      throughput  = var.runner_worker_docker_autoscaler_asg.volume_type == "gp3" ? var.runner_worker_docker_autoscaler_asg.volume_throughput : null
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

  tags = local.tags

  metadata_options {
    http_tokens                 = var.runner_worker_docker_autoscaler_asg.http_tokens
    http_put_response_hop_limit = var.runner_worker_docker_autoscaler_asg.http_put_response_hop_limit
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

  name = "${local.name_runner_agent_instance}-asg"

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
  min_size                  = 0 # Will be overwrite by runner idle count
  desired_capacity          = var.runner_worker_docker_autoscaler_asg.idle_count
  health_check_grace_period = var.runner_worker_docker_autoscaler_asg.health_check_grace_period
  health_check_type         = var.runner_worker_docker_autoscaler_asg.health_check_type
  force_delete              = true

  load_balancers = var.runner_worker_docker_autoscaler_asg.load_balancers

  dynamic "tag" {
    for_each = local.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

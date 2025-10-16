#
# This file is responsible for creating the resources needed to run the docker autoscaler plugin from GitLab. It replaces the
# outdated docker+machine driver. The docker+machine driver is a legacy driver that is no longer maintained by GitLab.
#

####################################
###### Launch template Workers #####
####################################
resource "aws_launch_template" "this" {
  count = var.runner_worker.type == "docker-autoscaler" ? 1 : 0

  name          = "${local.name_runner_agent_instance}-worker-launch-template"
  user_data     = var.runner_worker_docker_autoscaler_instance.start_script_compression_algorithm == "gzip" ? base64gzip(var.runner_worker_docker_autoscaler_instance.start_script) : base64encode(var.runner_worker_docker_autoscaler_instance.start_script)
  image_id      = length(var.runner_worker_docker_autoscaler_ami_id) > 0 ? var.runner_worker_docker_autoscaler_ami_id : data.aws_ami.docker_autoscaler_by_filter[0].id
  instance_type = length(var.runner_worker_docker_autoscaler_asg.types) > 0 ? var.runner_worker_docker_autoscaler_asg.types[0] : var.runner_worker_docker_autoscaler_asg.default_instance_type
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
      kms_key_id = local.kms_key_arn != "" ? local.kms_key_arn : null
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

  # as per user decision. The module default is "required" for better security.
  # tfsec:ignore:aws-ec2-enforce-launch-config-http-token-imds
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
  suspended_processes   = ["AZRebalance"]

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

        dynamic "override" {
          for_each = var.runner_worker_docker_autoscaler_asg.instance_requirements
          content {
            instance_requirements {
              allowed_instance_types = override.value.allowed_instance_types
              cpu_manufacturers      = override.value.cpu_manufacturers
              instance_generations   = override.value.instance_generations
              burstable_performance  = override.value.burstable_performance
              dynamic "memory_mib" {
                for_each = [override.value.memory_mib]
                content {
                  max = memory_mib.value.max
                  min = memory_mib.value.min
                }
              }
              dynamic "vcpu_count" {
                for_each = [override.value.vcpu_count]
                content {
                  max = vcpu_count.value.max
                  min = vcpu_count.value.min
                }
              }
            }
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
    # do not change desired_capacity as this is controlled at runtime by the runner autoscaler
    ignore_changes = [
      desired_capacity
    ]
  }
}

resource "aws_iam_instance_profile" "docker_autoscaler" {
  count = var.runner_worker.type == "docker-autoscaler" ? 1 : 0
  name  = "${local.name_iam_objects}-docker-autoscaler"
  role  = aws_iam_role.docker_autoscaler[0].name
  tags  = local.tags
}

resource "tls_private_key" "autoscaler" {
  count = var.runner_worker.type == "docker-autoscaler" ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "autoscaler" {
  count = var.runner_worker.type == "docker-autoscaler" ? 1 : 0

  key_name   = "${var.environment}-${var.runner_worker_docker_autoscaler.key_pair_name}"
  public_key = tls_private_key.autoscaler[0].public_key_openssh

  tags = local.tags
}

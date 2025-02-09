resource "aws_key_pair" "fleet" {
  count = var.runner_worker_docker_machine_fleet.enable == true && var.runner_worker.type == "docker+machine" ? 1 : 0

  key_name   = "${var.environment}-${var.runner_worker_docker_machine_fleet.key_pair_name}"
  public_key = tls_private_key.fleet[0].public_key_openssh

  tags = local.tags
}

resource "tls_private_key" "fleet" {
  count = var.runner_worker_docker_machine_fleet.enable == true && var.runner_worker.type == "docker+machine" ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_launch_template" "fleet_gitlab_runner" {
  # checkov:skip=CKV_AWS_88:User can decide to add a public IP.
  # checkov:skip=CKV_AWS_79:User can decide to enable Metadata service V2. V2 is the default.
  # checkov:skip=CKV_AWS_341:Hop limit is user-defined and set to 2 by default as the workload might run in a Docker container.
  count       = var.runner_worker_docker_machine_fleet.enable == true && var.runner_worker.type == "docker+machine" ? 1 : 0
  name_prefix = "${local.name_runner_agent_instance}-worker-"

  key_name               = aws_key_pair.fleet[0].key_name
  image_id               = length(var.runner_worker_docker_machine_ami_id) > 0 ? var.runner_worker_docker_machine_ami_id : data.aws_ami.docker_machine_by_filter[0].id
  user_data              = base64gzip(var.runner_worker_docker_machine_instance.start_script)
  instance_type          = var.runner_worker_docker_machine_instance.types[0] # it will be override by the fleet
  update_default_version = true
  ebs_optimized          = var.runner_worker_docker_machine_instance.ebs_optimized
  monitoring {
    enabled = var.runner_worker_docker_machine_instance.monitoring
  }
  block_device_mappings {
    device_name = var.runner_worker_docker_machine_instance.root_device_name

    ebs {
      volume_size = var.runner_worker_docker_machine_instance.root_size
      volume_type = var.runner_worker_docker_machine_instance.volume_type
      iops        = contains(["gp3", "io1", "io2"], var.runner_worker_docker_machine_instance.volume_type) ? var.runner_worker_docker_machine_instance.volume_iops : null
      throughput  = var.runner_worker_docker_machine_instance.volume_type == "gp3" ? var.runner_worker_docker_machine_instance.volume_throughput : null
      encrypted   = true
      kms_key_id  = local.kms_key_arn
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.docker_machine[0].name
  }

  network_interfaces {
    security_groups             = [aws_security_group.docker_machine[0].id]
    associate_public_ip_address = !var.runner_worker_docker_machine_instance.private_address_only
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
  # tag_specifications for spot-instances-request do not work. Instance creation fails.

  tags = local.tags

  metadata_options {
    http_tokens                 = var.runner_worker_docker_machine_ec2_metadata_options.http_tokens
    http_put_response_hop_limit = var.runner_worker_docker_machine_ec2_metadata_options.http_put_response_hop_limit
    instance_metadata_tags      = "enabled"
  }

  lifecycle {
    create_before_destroy = true
  }
}

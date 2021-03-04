terraform {
  required_providers {
    aws    = "~>3.0"
    null   = "~>2.1"
    local  = "~>1.4"
    random = "~>2.3"
  }
}

provider "aws" {
  region = var.region
}

locals {
  instance_file = "${path.module}/instance_id.txt"
  specs = {
    for element in setproduct(var.subnets, var.instance_types) : "${element[0]}-${element[1]}" => {
      subnet_id     = element[0]
      instance_type = element[1]
    }
  }
  tags = merge({
    Name     = var.ec2_name
    WorkerId = random_uuid.worker.result
  }, var.tags)
}

data "aws_caller_identity" "this" {}

resource "random_uuid" "worker" {
}

# SSH key pair
resource "aws_key_pair" "docker_machine" {
  key_name   = "${var.dm_machine_name}@docker-machine"
  public_key = file(var.dm_ssh_public_key_file)
}

resource "aws_spot_fleet_request" "runner" {
  iam_fleet_role                      = var.spot_fleet_tagging_role_arn
  spot_price                          = var.spot_price
  tags                                = local.tags
  allocation_strategy                 = "diversified"
  terminate_instances_with_expiration = true
  wait_for_fulfillment                = false
  target_capacity                     = 1

  dynamic "launch_specification" {
    for_each = local.specs
    iterator = spec

    content {
      ami                    = var.image_id
      instance_type          = spec.value["instance_type"]
      spot_price             = var.spot_price
      subnet_id              = spec.value["subnet_id"]
      vpc_security_group_ids = var.security_group_ids
      ebs_optimized          = true
      key_name               = aws_key_pair.docker_machine.key_name
      iam_instance_profile   = var.iam_instance_profile
      tags                   = local.tags
      user_data              = var.user_data

      root_block_device {
        volume_size           = var.volume_size
        encrypted             = true
        delete_on_termination = true
      }
    }
  }
}

resource "null_resource" "wait_for_instance" {
  depends_on = [random_uuid.worker]
  triggers = {
    WORKER_ID          = random_uuid.worker.result
    AWS_DEFAULT_REGION = var.region
    INSTANCE_FILE      = local.instance_file
  }
  provisioner "local-exec" {
    environment = {
      WORKER_ID          = random_uuid.worker.result
      AWS_DEFAULT_REGION = var.region
      INSTANCE_FILE      = local.instance_file
    }
    command = <<-EOF
      function get_instance(){
        aws ec2 describe-instances --filter "Name=tag:WorkerId,Values=$WORKER_ID" --query 'Reservations[*].Instances[*].InstanceId' --output text
      }
      while [ -z $(get_instance) ]; do echo "Waiting for instance..."; sleep 2; done
      instance_id=$(get_instance)
      private_ip="$(aws ec2 describe-instances --instance-id $instance_id --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)"
      echo "$private_ip" >"$INSTANCE_FILE"
    EOF
  }
}

data "local_file" "instance_ip" {
  depends_on = [null_resource.wait_for_instance]
  filename   = local.instance_file
}

locals {
  worker_ip = trimspace(data.local_file.instance_ip.content)
}

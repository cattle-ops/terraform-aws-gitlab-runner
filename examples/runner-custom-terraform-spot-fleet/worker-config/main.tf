terraform {
  required_providers {
    aws  = "~>3.0"
    null = "~>2.1"
  }
}

provider "aws" {
  region = var.region
}

locals {
  instance_id_file = "${path.module}/instance_id.txt"
  specs = {
    for element in setproduct(var.subnets, var.instance_types) : "${element[0]}-${element[1]}" => {
      subnet_id     = element[0]
      instance_type = element[1]
    }
  }
  tags = merge({
    Name = var.dm_machine_name
  }, var.tags)
}

data "aws_caller_identity" "this" {}

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

      root_block_device {
        volume_size           = var.volume_size
        encrypted             = true
        delete_on_termination = true
      }
    }
  }
}

resource "null_resource" "runner_id" {
  depends_on = [aws_spot_fleet_request.runner]
  provisioner "local-exec" {
    environment = {
      AWS_DEFAULT_REGION = var.region
      MACHINE_NAME       = var.dm_machine_name
      INSTANCE_ID_FILE   = local.instance_id_file
    }
    command = <<EOF
      function get_instance(){
        aws ec2 describe-instances --filter "Name=tag:Name,Values=$MACHINE_NAME" --query 'Reservations[*].Instances[*].InstanceId' --output text
      }
      while [ -z $(get_instance) ]; do echo "Waiting for instance..."; sleep 2; done
      get_instance >"$INSTANCE_ID_FILE"
    EOF
  }
}

data "local_file" "instance_id" {
  depends_on = [null_resource.runner_id]
  filename   = local.instance_id_file
}

data "aws_instance" "runner" {
  depends_on  = [data.local_file.instance_id]
  instance_id = trimspace(data.local_file.instance_id.content)
}

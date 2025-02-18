locals {
  template_runner_docker_machine = templatefile("${path.module}/template/runner-docker-machine-config.tftpl",
    {
      runners_idle_count     = var.runner_worker_docker_machine_instance.idle_count
      runners_idle_time      = var.runner_worker_docker_machine_instance.idle_time
      runners_max_builds     = local.runners_max_builds_string
      docker_machine_name    = format("%s-%s", local.runner_tags_merged["Name"], "%s") # %s is always needed
      runners_instance_types = var.runner_worker_docker_machine_instance.types
      aws_region             = data.aws_region.current.name
      runners_aws_zone       = data.aws_availability_zone.runners.name_suffix
      runners_userdata       = var.runner_worker_docker_machine_instance.start_script

      runners_vpc_id           = var.vpc_id
      runners_subnet_id        = var.subnet_id
      runners_subnet_ids       = length(var.runner_worker_docker_machine_instance.subnet_ids) > 0 ? var.runner_worker_docker_machine_instance.subnet_ids : [var.subnet_id]
      runners_instance_profile = var.runner_worker.type == "docker+machine" ? aws_iam_instance_profile.docker_machine[0].name : ""

      runners_use_private_address_only = var.runner_worker_docker_machine_instance.private_address_only
      runners_use_private_address      = !var.runner_worker_docker_machine_instance.private_address_only
      runners_request_spot_instance    = var.runner_worker_docker_machine_instance_spot.enable
      runners_spot_price_bid           = var.runner_worker_docker_machine_instance_spot.max_price == "on-demand-price" || var.runner_worker_docker_machine_instance_spot.max_price == null ? "" : var.runner_worker_docker_machine_instance_spot.max_price
      runners_security_group_name      = var.runner_worker.type == "docker+machine" ? aws_security_group.docker_machine[0].name : ""

      runners_tags                      = replace(replace(local.runner_tags_string, ",,", ","), "/,$/", "")
      runners_ebs_optimized             = var.runner_worker_docker_machine_instance.ebs_optimized
      runners_monitoring                = var.runner_worker_docker_machine_instance.monitoring
      runners_iam_instance_profile_name = var.runner_worker_docker_machine_role.profile_name
      runners_root_size                 = var.runner_worker_docker_machine_instance.root_size
      runners_volume_type               = var.runner_worker_docker_machine_instance.volume_type
      runners_ami                       = var.runner_worker.type == "docker+machine" ? (length(var.runner_worker_docker_machine_ami_id) > 0 ? var.runner_worker_docker_machine_ami_id : data.aws_ami.docker_machine_by_filter[0].id) : ""
      use_fleet                         = var.runner_worker_docker_machine_fleet.enable
      launch_template                   = var.runner_worker_docker_machine_fleet.enable == true ? aws_launch_template.fleet_gitlab_runner[0].name : ""
      docker_machine_options            = length(local.docker_machine_options_string) == 1 ? "" : local.docker_machine_options_string
      runners_max_growth_rate           = var.runner_worker_docker_machine_instance.max_growth_rate
      runners_volume_kms_key            = local.kms_key_arn
  })
}

resource "aws_iam_instance_profile" "docker_machine" {
  count = var.runner_worker.type == "docker+machine" ? 1 : 0
  name  = "${local.name_iam_objects}-docker-machine"
  role  = aws_iam_role.docker_machine[0].name
  tags  = local.tags
}

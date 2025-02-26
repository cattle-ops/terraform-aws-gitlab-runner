locals {
  template_runner_worker_config = templatefile("${path.module}/template/runner-definition.tftpl",
    {
      aws_region       = data.aws_region.current.name
      gitlab_url       = var.runner_gitlab.url
      gitlab_clone_url = var.runner_gitlab.url_clone
      tls_ca_file      = length(var.runner_gitlab.certificate) > 0 ? "tls-ca-file=\"/etc/gitlab-runner/certs/gitlab.crt\"" : ""
      runners_machine_autoscaling = [for config in var.docker_machine_autoscaling_options : {
        for key, value in config :
        # Convert key from snake_case to PascalCase which is the casing for this section.
        join("", [for subkey in split("_", key) : title(subkey)]) => jsonencode(value) if value != null
      }]

      runners_name                   = var.runner_instance.name
      runners_token                  = var.runner_gitlab.registration_token
      runners_executor               = var.runner_worker.type
      runners_limit                  = var.runner_worker.max_jobs
      runners_environment_vars       = jsonencode(var.runner_worker.environment_variables)
      runners_pre_build_script       = var.gitlab_pipeline.pre_build_script
      runners_post_build_script      = var.gitlab_pipeline.post_build_script
      runners_pre_clone_script       = var.gitlab_pipeline.pre_clone_script
      runners_request_concurrency    = var.runner_worker.request_concurrency
      runners_output_limit           = var.runner_worker.output_limit
      runners_volumes_tmpfs          = join("\n", [for v in var.docker_volumes_tmpfs : format("\"%s\" = \"%s\"", v.volume, v.options)])
      runners_services_volumes_tmpfs = join("\n", [for v in var.docker_services_volumes_tmpfs : format("\"%s\" = \"%s\"", v.volume, v.options)])
      runners_docker_services        = local.runners_docker_services
      runners_docker_options         = local.runners_docker_options_toml
      bucket_name                    = var.cache_bucket_name
      shared_cache                   = var.cache.shared
      auth_type                      = var.cache.authentication_type
      runners_docker_autoscaler      = var.runner_worker.type == "docker-autoscaler" ? local.template_runner_docker_autoscaler : ""
      runners_docker_machine         = var.runner_worker.type == "docker+machine" ? local.template_runner_docker_machine : ""
    }
  )

  template_runner_docker_autoscaler = templatefile("${path.module}/template/runner-docker-autoscaler-config.tftpl",
    {
      docker_autoscaling_name       = var.docker_autoscaler_asg_name
      connector_config_user         = var.docker_autoscaler.connector_config_user
      runners_capacity_per_instance = var.docker_autoscaler.capacity_per_instance
      runners_max_use_count         = var.docker_autoscaler.max_use_count
      runners_max_instances         = var.runner_worker.max_jobs

      runners_update_interval                = var.docker_autoscaler.update_interval
      runners_update_interval_when_expecting = var.docker_autoscaler.update_interval_when_expecting

      runners_instance_ready_command = var.docker_autoscaler.instance_ready_command

      use_private_key = var.runner_worker.use_private_key && var.runner_worker.type == "docker-autoscaler"

      runners_autoscaling = [for config in var.docker_autoscaler_autoscaling_options : {
        for key, value in config :
        # Convert key from snake_case to PascalCase which is the casing for this section.
        key => jsonencode(value) if value != null
      }]
  })

  template_runner_docker_machine = templatefile("${path.module}/template/runner-docker-machine-config.tftpl",
    {
      runners_idle_count     = var.docker_machine_instance.idle_count
      runners_idle_time      = var.docker_machine_instance.idle_time
      runners_max_builds     = local.runners_max_builds_string
      docker_machine_name    = format("%s-%s", var.docker_machine_runner_name, "%s") # the last %s is always needed
      runners_instance_types = var.docker_machine_instance.types
      aws_region             = data.aws_region.current.name
      runners_aws_zone       = var.docker_machine_availability_zone_name
      runners_userdata       = var.docker_machine_instance.start_script

      runners_vpc_id           = var.vpc_id
      runners_subnet_id        = var.subnet_id
      runners_subnet_ids       = length(var.docker_machine_instance.subnet_ids) > 0 ? var.docker_machine_instance.subnet_ids : [var.subnet_id]
      runners_instance_profile = var.docker_machine_availability_zone_name

      runners_use_private_address_only = var.docker_machine_instance.private_address_only
      runners_use_private_address      = !var.docker_machine_instance.private_address_only
      runners_request_spot_instance    = var.docker_machine_instance_spot.enable
      runners_spot_price_bid           = var.docker_machine_instance_spot.max_price == "on-demand-price" || var.docker_machine_instance_spot.max_price == null ? "" : var.docker_machine_instance_spot.max_price
      runners_security_group_name      = var.docker_machine_security_group_name

      runners_tags                      = replace(replace(local.runner_tags_string, ",,", ","), "/,$/", "")
      runners_ebs_optimized             = var.docker_machine_instance.ebs_optimized
      runners_monitoring                = var.docker_machine_instance.monitoring
      runners_iam_instance_profile_name = var.docker_machine_role.profile_name
      runners_root_size                 = var.docker_machine_instance.root_size
      runners_volume_type               = var.docker_machine_instance.volume_type
      runners_ami                       = var.runner_worker.type == "docker+machine" ? (length(var.docker_machine_ami_id) > 0 ? var.docker_machine_ami_id : var.docker_machine_ami_id) : ""
      use_fleet                         = var.docker_machine_fleet.enable
      launch_template                   = var.docker_machine_fleet_launch_template_name
      docker_machine_options            = length(local.docker_machine_options_string) == 1 ? "" : local.docker_machine_options_string
      runners_max_growth_rate           = var.docker_machine_instance.max_growth_rate
      runners_volume_kms_key            = var.kms_key_arn
  })

  runners_docker_services = templatefile("${path.module}/template/runners_docker_services.tftpl", {
    runners_docker_services = var.docker_services
    }
  )

  runners_docker_options_toml = templatefile("${path.module}/template/runners_docker_options.tftpl", {
    options = merge({
      for key, value in var.docker_options : key => value if value != null && key != "volumes" && key != "pull_policies"
      }, {
      pull_policy = var.docker_options.pull_policies
      volumes     = local.runners_volumes
    })
    }
  )

  # Convert list to a string separated and prepend by a comma
  docker_machine_options_string = format(
    ",\"amazonec2-metadata-token=${var.docker_machine_ec2_metadata_options.http_tokens}\", \"amazonec2-metadata-token-response-hop-limit=${var.docker_machine_ec2_metadata_options.http_put_response_hop_limit}\",%s",
    join(",", formatlist("%q", concat(var.docker_machine_ec2_options, local.runners_docker_registry_mirror_option))),
  )

  runners_volumes = concat(var.docker_options.volumes, var.docker_add_dind_volumes ? ["/certs/client", "/builds", "/var/run/docker.sock:/var/run/docker.sock"] : [])

  runner_tags_string = join(",", flatten([
    for key in keys(local.runner_tags) : [key, local.runner_tags[key]]
  ]))

  # remove the `Name` tag in addition if docker+machine adds one to avoid a failure due to a duplicate `Name` tag
  runner_tags = local.docker_machine_adds_name_tag ? { for k, v in var.docker_machine_tags : k => v if !contains(concat(var.suppressed_tags, ["Name"]), k) } : var.docker_machine_tags

  # Ensure max builds is optional
  runners_max_builds_string = var.docker_machine_instance.destroy_after_max_builds == 0 ? "" : format("MaxBuilds = %d", var.docker_machine_instance.destroy_after_max_builds)

  runners_docker_registry_mirror_option = var.docker_machine_instance.docker_registry_mirror_url == "" ? [] : ["engine-registry-mirror=${var.docker_machine_instance.docker_registry_mirror_url}"]
  docker_machine_adds_name_tag          = signum(sum(local.docker_machine_version_test)) <= 0
  docker_machine_version_test = [
    for i, j in reverse(range(length(local.docker_machine_version_used)))
    : signum(local.docker_machine_version_with_name_tag[i] - local.docker_machine_version_used[i]) * pow(10, j)
  ]

  /* determines if the docker machine executable adds the Name tag automatically (versions >= 0.16.2) */
  # make sure to skip pre-release stuff in the semver by ignoring everything after "-"
  docker_machine_version_used          = split(".", split("-", var.runner_install.docker_machine_version)[0])
  docker_machine_version_with_name_tag = split(".", "0.16.2")
}

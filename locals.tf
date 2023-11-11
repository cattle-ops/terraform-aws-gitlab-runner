locals {
  # Manage certificates
  pre_install_gitlab_certificate = (
    length(var.runner_gitlab.certificate) > 0
    ? <<-EOT
      mkdir -p /etc/gitlab-runner/certs/
      cat <<- EOF > /etc/gitlab-runner/certs/gitlab.crt
      ${var.runner_gitlab.certificate}
      EOF
    EOT
    : ""
  )
  pre_install_ca_certificate = (
    length(var.runner_gitlab.ca_certificate) > 0
    ? <<-EOT
      mkdir -p /etc/gitlab-runner/certs/
      cat <<- EOF > /etc/gitlab-runner/certs/ca.crt
      ${var.runner_gitlab.ca_certificate}
      EOF
    EOT
    : ""
  )
  pre_install_certificates_end = <<-EOT
    chmod 600 /etc/gitlab-runner/certs/*.crt
    chmod -R a+r /etc/gitlab-runner
    cp /etc/gitlab-runner/certs/*.crt /etc/pki/ca-trust/source/anchors
    update-ca-trust extract
  EOT
  pre_install_certificates = (
    # If either (or both) _certificate variables are specified
    length(var.runner_gitlab.certificate) + length(var.runner_gitlab.ca_certificate) > 0
    ? join("\n", [
      local.pre_install_gitlab_certificate,
      local.pre_install_ca_certificate,
      local.pre_install_certificates_end
    ])
    : ""
  )

  # Determine IAM role for runner instance
  aws_iam_role_instance_name = coalesce(
    var.runner_role.role_profile_name,
    "${local.name_iam_objects}-instance"
  )
  aws_iam_role_instance_arn = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${local.aws_iam_role_instance_name}"

  # Convert list to a string separated and prepend by a comma
  docker_machine_options_string = format(
    ",\"amazonec2-metadata-token=${var.runner_worker_docker_machine_ec2_metadata_options.http_tokens}\", \"amazonec2-metadata-token-response-hop-limit=${var.runner_worker_docker_machine_ec2_metadata_options.http_put_response_hop_limit}\",%s",
    join(",", formatlist("%q", concat(var.runner_worker_docker_machine_ec2_options, local.runners_docker_registry_mirror_option))),
  )

  runners_docker_registry_mirror_option = var.runner_worker_docker_machine_instance.docker_registry_mirror_url == "" ? [] : ["engine-registry-mirror=${var.runner_worker_docker_machine_instance.docker_registry_mirror_url}"]

  runners_docker_options_toml = templatefile("${path.module}/template/runners_docker_options.tftpl", {
    options = merge({
      for key, value in var.runner_worker_docker_options : key => value if value != null && key != "volumes"
      }, {
      volumes = local.runners_volumes
    })
    }
  )

  # Ensure max builds is optional
  runners_max_builds_string = var.runner_worker_docker_machine_instance.destroy_after_max_builds == 0 ? "" : format("MaxBuilds = %d", var.runner_worker_docker_machine_instance.destroy_after_max_builds)

  # Define key for runner token for SSM
  secure_parameter_store_runner_token_key  = "${var.environment}-${var.runner_gitlab_token_secure_parameter_store}"
  secure_parameter_store_runner_sentry_dsn = "${var.environment}-${var.runner_sentry_secure_parameter_store_name}"

  # Custom names for runner agent instance, security groups, and IAM objects
  name_runner_agent_instance = var.runner_instance.name_prefix == null ? local.tags["Name"] : var.runner_instance.name_prefix
  name_sg                    = var.security_group_prefix == "" ? local.tags["Name"] : var.security_group_prefix
  name_iam_objects           = var.iam_object_prefix == "" ? local.tags["Name"] : var.iam_object_prefix

  runners_volumes = concat(var.runner_worker_docker_options.volumes, var.runner_worker_docker_add_dind_volumes ? ["/certs/client", "/builds", "/var/run/docker.sock:/var/run/docker.sock"] : [])

  runners_docker_services = templatefile("${path.module}/template/runners_docker_services.tftpl", {
    runners_docker_services = var.runner_worker_docker_services
    }
  )

  runners_pull_policies = "[\"${join("\",\"", var.runner_worker_docker_options.pull_policies)}\"]"

  /* determines if the docker machine executable adds the Name tag automatically (versions >= 0.16.2) */
  # make sure to skip pre-release stuff in the semver by ignoring everything after "-"
  docker_machine_version_used          = split(".", split("-", var.runner_install.docker_machine_version)[0])
  docker_machine_version_with_name_tag = split(".", "0.16.2")
  docker_machine_version_test = [
    for i, j in reverse(range(length(local.docker_machine_version_used)))
    : signum(local.docker_machine_version_with_name_tag[i] - local.docker_machine_version_used[i]) * pow(10, j)
  ]

  docker_machine_adds_name_tag = signum(sum(local.docker_machine_version_test)) <= 0

  template_user_data = templatefile("${path.module}/template/user-data.tftpl",
    {
      eip                 = var.runner_instance.use_eip ? local.template_eip : ""
      logging             = var.runner_cloudwatch.enable ? local.logging_user_data : ""
      gitlab_runner       = local.template_gitlab_runner
      user_data_trace_log = var.debug.trace_runner_user_data
      yum_update          = var.runner_install.yum_update ? local.file_yum_update : ""
      extra_config        = var.runner_install.start_script
  })

  file_yum_update = file("${path.module}/template/yum_update.tftpl")

  template_eip = templatefile("${path.module}/template/eip.tftpl", {
    eip = join(",", [for eip in aws_eip.gitlab_runner : eip.public_ip])
  })

  template_gitlab_runner = templatefile("${path.module}/template/gitlab-runner.tftpl",
    {
      gitlab_runner_version                                        = var.runner_gitlab.runner_version
      docker_machine_version                                       = var.runner_install.docker_machine_version
      docker_machine_download_url                                  = var.runner_install.docker_machine_download_url
      runners_config                                               = local.template_runner_config
      runners_userdata                                             = var.runner_worker_docker_machine_instance.start_script
      runners_executor                                             = var.runner_worker.type
      runners_install_amazon_ecr_credential_helper                 = var.runner_install.amazon_ecr_credential_helper
      curl_cacert                                                  = length(var.runner_gitlab.certificate) > 0 ? "--cacert /etc/gitlab-runner/certs/gitlab.crt" : ""
      pre_install_certificates                                     = local.pre_install_certificates
      pre_install                                                  = var.runner_install.pre_install_script
      post_install                                                 = var.runner_install.post_install_script
      runners_gitlab_url                                           = var.runner_gitlab.url
      runners_token                                                = var.runner_gitlab.registration_token
      secure_parameter_store_gitlab_runner_registration_token_name = var.runner_gitlab_registration_token_secure_parameter_store_name
      secure_parameter_store_runner_token_key                      = local.secure_parameter_store_runner_token_key
      secure_parameter_store_runner_sentry_dsn                     = local.secure_parameter_store_runner_sentry_dsn
      secure_parameter_store_gitlab_token_name                     = var.runner_gitlab.access_token_secure_parameter_store_name
      secure_parameter_store_region                                = data.aws_region.current.name
      gitlab_runner_registration_token                             = var.runner_gitlab_registration_config.registration_token
      gitlab_runner_description                                    = var.runner_gitlab_registration_config["description"]
      gitlab_runner_tag_list                                       = var.runner_gitlab_registration_config["tag_list"]
      gitlab_runner_locked_to_project                              = var.runner_gitlab_registration_config["locked_to_project"]
      gitlab_runner_run_untagged                                   = var.runner_gitlab_registration_config["run_untagged"]
      gitlab_runner_maximum_timeout                                = var.runner_gitlab_registration_config["maximum_timeout"]
      gitlab_runner_type                                           = var.runner_gitlab_registration_config["type"]
      gitlab_runner_group_id                                       = var.runner_gitlab_registration_config["group_id"]
      gitlab_runner_project_id                                     = var.runner_gitlab_registration_config["project_id"]
      gitlab_runner_access_level                                   = var.runner_gitlab_registration_config.access_level
      sentry_dsn                                                   = var.runner_manager.sentry_dsn
      public_key                                                   = var.runner_worker_docker_machine_fleet.enable == true ? tls_private_key.fleet[0].public_key_openssh : ""
      use_fleet                                                    = var.runner_worker_docker_machine_fleet.enable
      private_key                                                  = var.runner_worker_docker_machine_fleet.enable == true ? tls_private_key.fleet[0].private_key_pem : ""
      use_new_runner_authentication_gitlab_16                      = var.runner_gitlab_registration_config.type != ""
  })

  template_runner_config = templatefile("${path.module}/template/runner-config.tftpl",
    {
      aws_region       = data.aws_region.current.name
      gitlab_url       = var.runner_gitlab.url
      gitlab_clone_url = var.runner_gitlab.url_clone
      tls_ca_file      = length(var.runner_gitlab.certificate) > 0 ? "tls-ca-file=\"/etc/gitlab-runner/certs/gitlab.crt\"" : ""
      runners_machine_autoscaling = [for config in var.runner_worker_docker_machine_autoscaling_options : {
        for key, value in config :
        # Convert key from snake_case to PascalCase which is the casing for this section.
        join("", [for subkey in split("_", key) : title(subkey)]) => jsonencode(value) if value != null
      }]
      runners_vpc_id                    = var.vpc_id
      runners_subnet_id                 = var.subnet_id
      runners_subnet_ids                = length(var.runner_worker_docker_machine_instance.subnet_ids) > 0 ? var.runner_worker_docker_machine_instance.subnet_ids : [var.subnet_id]
      runners_aws_zone                  = data.aws_availability_zone.runners.name_suffix
      runners_instance_types            = var.runner_worker_docker_machine_instance.types
      runners_spot_price_bid            = var.runner_worker_docker_machine_instance_spot.max_price == "on-demand-price" || var.runner_worker_docker_machine_instance_spot.max_price == null ? "" : var.runner_worker_docker_machine_instance_spot.max_price
      runners_ami                       = var.runner_worker.type == "docker+machine" ? data.aws_ami.docker-machine[0].id : ""
      runners_security_group_name       = var.runner_worker.type == "docker+machine" ? aws_security_group.docker_machine[0].name : ""
      runners_max_growth_rate           = var.runner_worker_docker_machine_instance.max_growth_rate
      runners_monitoring                = var.runner_worker_docker_machine_instance.monitoring
      runners_ebs_optimized             = var.runner_worker_docker_machine_instance.ebs_optimized
      runners_instance_profile          = var.runner_worker.type == "docker+machine" ? aws_iam_instance_profile.docker_machine[0].name : ""
      docker_machine_options            = length(local.docker_machine_options_string) == 1 ? "" : local.docker_machine_options_string
      docker_machine_name               = format("%s-%s", local.runner_tags_merged["Name"], "%s") # %s is always needed
      runners_name                      = var.runner_instance.name
      runners_tags                      = replace(replace(local.runner_tags_string, ",,", ","), "/,$/", "")
      runners_token                     = var.runner_gitlab.registration_token
      runners_userdata                  = var.runner_worker_docker_machine_instance.start_script
      runners_executor                  = var.runner_worker.type
      runners_limit                     = var.runner_worker.max_jobs
      runners_concurrent                = var.runner_manager.maximum_concurrent_jobs
      runners_pull_policies             = local.runners_pull_policies
      runners_idle_count                = var.runner_worker_docker_machine_instance.idle_count
      runners_idle_time                 = var.runner_worker_docker_machine_instance.idle_time
      runners_max_builds                = local.runners_max_builds_string
      runners_root_size                 = var.runner_worker_docker_machine_instance.root_size
      runners_volume_type               = var.runner_worker_docker_machine_instance.volume_type
      runners_iam_instance_profile_name = var.runner_worker_docker_machine_role.profile_name
      runners_use_private_address_only  = var.runner_worker_docker_machine_instance.private_address_only
      runners_use_private_address       = !var.runner_worker_docker_machine_instance.private_address_only
      runners_request_spot_instance     = var.runner_worker_docker_machine_instance_spot.enable
      runners_environment_vars          = jsonencode(var.runner_worker.environment_variables)
      runners_pre_build_script          = var.runner_worker_gitlab_pipeline.pre_build_script
      runners_post_build_script         = var.runner_worker_gitlab_pipeline.post_build_script
      runners_pre_clone_script          = var.runner_worker_gitlab_pipeline.pre_clone_script
      runners_request_concurrency       = var.runner_worker.request_concurrency
      runners_output_limit              = var.runner_worker.output_limit
      runners_check_interval            = var.runner_manager.gitlab_check_interval
      runners_volumes_tmpfs             = join("\n", [for v in var.runner_worker_docker_volumes_tmpfs : format("\"%s\" = \"%s\"", v.volume, v.options)])
      runners_services_volumes_tmpfs    = join("\n", [for v in var.runner_worker_docker_services_volumes_tmpfs : format("\"%s\" = \"%s\"", v.volume, v.options)])
      runners_docker_services           = local.runners_docker_services
      runners_docker_options            = local.runners_docker_options_toml
      bucket_name                       = local.bucket_name
      shared_cache                      = var.runner_worker_cache.shared
      sentry_dsn                        = var.runner_manager.sentry_dsn
      prometheus_listen_address         = var.runner_manager.prometheus_listen_address
      auth_type                         = var.runner_worker_cache.authentication_type
      use_fleet                         = var.runner_worker_docker_machine_fleet.enable
      launch_template                   = var.runner_worker_docker_machine_fleet.enable == true ? aws_launch_template.fleet_gitlab_runner[0].name : ""
    }
  )
}

resource "local_file" "config_toml" {
  count = var.debug.write_runner_config_to_file ? 1 : 0

  content  = local.template_runner_config
  filename = "${path.root}/debug/${local.name_runner_agent_instance}/runner_config.toml"
}

resource "local_file" "user_data" {
  count = var.debug.write_runner_user_data_to_file ? 1 : 0

  content  = local.template_user_data
  filename = "${path.root}/debug/${local.name_runner_agent_instance}/user_data.sh"
}

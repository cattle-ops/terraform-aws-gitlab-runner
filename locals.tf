locals {
  # Convert list to a string separated and prepend by a comma
  docker_machine_options_string = format(
    ",\"amazonec2-metadata-token=${var.docker_machine_instance_metadata_options.http_tokens}\", \"amazonec2-metadata-token-response-hop-limit=${var.docker_machine_instance_metadata_options.http_put_response_hop_limit}\",%s",
    join(",", formatlist("%q", concat(var.docker_machine_options, local.runners_docker_registry_mirror_option))),
  )

  runners_docker_registry_mirror_option = var.runners_docker_registry_mirror == "" ? [] : ["engine-registry-mirror=${var.runners_docker_registry_mirror}"]

  runners_docker_options = var.runners_docker_options != null ? local.template_runners_docker_options : local.runners_docker_options_single_string

  template_runners_docker_options = var.runners_docker_options == null ? "" : templatefile("${path.module}/template/runners_docker_options.tpl", {
    disable_cache = var.runners_docker_options.disable_cache
    image         = var.runners_docker_options.image
    privileged    = var.runners_docker_options.privileged
    pull_policy   = var.runners_docker_options.pull_policy
    shm_size      = var.runners_docker_options.shm_size
    tls_verify    = var.runners_docker_options.tls_verify
    volumes       = local.runners_docker_volumes

    allowed_images               = var.runners_docker_options.allowed_images == null ? null : join(", ", [for s in var.runners_docker_options.allowed_images : format("\"%s\"", s)])
    allowed_pull_policies        = var.runners_docker_options.allowed_pull_policies == null ? null : join(", ", [for s in var.runners_docker_options.allowed_pull_policies : format("\"%s\"", s)])
    allowed_services             = var.runners_docker_options.allowed_services == null ? null : join(", ", [for s in var.runners_docker_options.allowed_services : format("\"%s\"", s)])
    cache_dir                    = var.runners_docker_options.cache_dir
    cap_add                      = var.runners_docker_options.cap_add == null ? null : join(", ", [for s in var.runners_docker_options.cap_add : format("\"%s\"", s)])
    cap_drop                     = var.runners_docker_options.cap_drop == null ? null : join(", ", [for s in var.runners_docker_options.cap_drop : format("\"%s\"", s)])
    container_labels             = var.runners_docker_options.container_labels == null ? null : join(", ", [for s in var.runners_docker_options.container_labels : format("\"%s\"", s)])
    cpuset_cpus                  = var.runners_docker_options.cpuset_cpus
    cpu_shares                   = var.runners_docker_options.cpu_shares
    cpus                         = var.runners_docker_options.cpus
    devices                      = var.runners_docker_options.devices == null ? null : join(", ", [for s in var.runners_docker_options.devices : format("\"%s\"", s)])
    device_cgroup_rules          = var.runners_docker_options.device_cgroup_rules == null ? null : join(", ", [for s in var.runners_docker_options.device_cgroup_rules : format("\"%s\"", s)])
    disable_entrypoint_overwrite = var.runners_docker_options.disable_entrypoint_overwrite
    dns                          = var.runners_docker_options.dns == null ? null : join(", ", [for s in var.runners_docker_options.dns : format("\"%s\"", s)])
    dns_search                   = var.runners_docker_options.dns_search == null ? null : join(", ", [for s in var.runners_docker_options.dns_search : format("\"%s\"", s)])
    extra_hosts                  = var.runners_docker_options.extra_hosts == null ? null : join(", ", [for s in var.runners_docker_options.extra_hosts : format("\"%s\"", s)])
    gpus                         = var.runners_docker_options.gpus
    helper_image                 = var.runners_docker_options.helper_image
    helper_image_flavor          = var.runners_docker_options.helper_image_flavor
    host                         = var.runners_docker_options.host
    hostname                     = var.runners_docker_options.hostname
    links                        = var.runners_docker_options.links == null ? null : join(", ", [for s in var.runners_docker_options.links : format("\"%s\"", s)])
    memory                       = var.runners_docker_options.memory
    memory_reservation           = var.runners_docker_options.memory_reservation
    memory_swap                  = var.runners_docker_options.memory_swap
    network_mode                 = var.runners_docker_options.network_mode
    oom_kill_disable             = var.runners_docker_options.oom_kill_disable
    oom_score_adjust             = var.runners_docker_options.oom_score_adjust
    runtime                      = var.runners_docker_options.runtime
    security_opt                 = var.runners_docker_options.security_opt == null ? null : join(", ", [for s in var.runners_docker_options.security_opt : format("\"%s\"", s)])
    sysctls                      = var.runners_docker_options.sysctls == null ? null : join(", ", [for s in var.runners_docker_options.sysctls : format("\"%s\"", s)])
    tls_cert_path                = var.runners_docker_options.tls_cert_path
    userns_mode                  = var.runners_docker_options.userns_mode
    volume_driver                = var.runners_docker_options.volume_driver
    volumes_from                 = var.runners_docker_options.volumes_from == null ? null : join(", ", [for s in var.runners_docker_options.volumes_from : format("\"%s\"", s)])
    wait_for_services_timeout    = var.runners_docker_options.wait_for_services_timeout
  })
  runners_docker_options_single_string = <<-EOT
    tls_verify = false
    image = "${var.runners_image}"
    privileged = ${var.runners_privileged}
    disable_cache = ${var.runners_disable_cache}
    volumes = [${local.runners_docker_volumes}]
    shm_size = ${var.runners_shm_size}
    pull_policy = "${var.runners_pull_policy}"
    runtime = "${var.runners_docker_runtime}"
    helper_image = "${var.runners_helper_image}"
  EOT

  runners_docker_volumes = join(", ", formatlist("\"%s\"", concat(["/cache"], var.runners_additional_volumes)))

  # Ensure max builds is optional
  runners_max_builds_string = var.runners_max_builds == 0 ? "" : format("MaxBuilds = %d", var.runners_max_builds)

  # Define key for runner token for SSM
  secure_parameter_store_runner_token_key  = "${var.environment}-${var.secure_parameter_store_runner_token_key}"
  secure_parameter_store_runner_sentry_dsn = "${var.environment}-${var.secure_parameter_store_runner_sentry_dsn}"

  # Custom names for runner agent instance, security groups, and IAM objects
  name_runner_agent_instance = var.overrides["name_runner_agent_instance"] == "" ? local.tags["Name"] : var.overrides["name_runner_agent_instance"]
  name_sg                    = var.overrides["name_sg"] == "" ? local.tags["Name"] : var.overrides["name_sg"]
  name_iam_objects           = lookup(var.overrides, "name_iam_objects", "") == "" ? local.tags["Name"] : var.overrides["name_iam_objects"]
  runners_additional_volumes = <<-EOT
  %{~if var.runners_add_dind_volumes~},"/certs/client", "/builds", "/var/run/docker.sock:/var/run/docker.sock"%{endif~}%{~for volume in var.runners_additional_volumes~},"${volume}"%{endfor~}
  EOT

  runners_machine_autoscaling = templatefile("${path.module}/template/runners_machine_autoscaling.tpl", {
    runners_machine_autoscaling = var.runners_machine_autoscaling
    }
  )

  /* determines if the docker machine executable adds the Name tag automatically (versions >= 0.16.2) */
  # make sure to skip pre-release stuff in the semver by ignoring everything after "-"
  docker_machine_version_used          = split(".", split("-", var.docker_machine_version)[0])
  docker_machine_version_with_name_tag = split(".", "0.16.2")
  docker_machine_version_test = [
    for i, j in reverse(range(length(local.docker_machine_version_used)))
    : signum(local.docker_machine_version_with_name_tag[i] - local.docker_machine_version_used[i]) * pow(10, j)
  ]

  docker_machine_adds_name_tag = signum(sum(local.docker_machine_version_test)) <= 0
}
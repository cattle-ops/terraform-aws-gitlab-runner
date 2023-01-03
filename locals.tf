locals {
  # Determine IAM role for runner instance
  aws_iam_role_instance_name = coalesce(
    var.runner_iam_role_name,
    "${local.name_iam_objects}-instance"
  )
  aws_iam_role_instance_arn = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${local.aws_iam_role_instance_name}"

  # Convert list to a string separated and prepend by a comma
  docker_machine_options_string = format(
    ",\"amazonec2-metadata-token=${var.docker_machine_instance_metadata_options.http_tokens}\", \"amazonec2-metadata-token-response-hop-limit=${var.docker_machine_instance_metadata_options.http_put_response_hop_limit}\",%s",
    join(",", formatlist("%q", concat(var.docker_machine_options, local.runners_docker_registry_mirror_option))),
  )

  runners_docker_registry_mirror_option = var.runners_docker_registry_mirror == "" ? [] : ["engine-registry-mirror=${var.runners_docker_registry_mirror}"]

  # Ensure max builds is optional
  runners_max_builds_string = var.runners_max_builds == 0 ? "" : format("MaxBuilds = %d", var.runners_max_builds)

  secure_parameter_store_runner_token_key  = "${var.environment}-runner-token"
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

  runners_docker_services = templatefile("${path.module}/template/runners_docker_services.tpl", {
    runners_docker_services = var.runners_docker_services
    }
  )

  runners_pull_policies = var.runners_pull_policy != "" ? "[\"${var.runners_pull_policy}\"]" : "[\"${join("\",\"", var.runners_pull_policies)}\"]"

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

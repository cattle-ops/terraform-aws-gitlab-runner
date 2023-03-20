locals {
  # Manage certificates
  pre_install_gitlab_certificate = (
    length(var.runners_gitlab_certificate) > 0
    ? <<-EOT
      mkdir -p /etc/gitlab-runner/certs/
      cat <<- EOF > /etc/gitlab-runner/certs/gitlab.crt
      ${var.runners_gitlab_certificate}
      EOF
    EOT
    : ""
  )
  pre_install_ca_certificate = (
    length(var.runners_ca_certificate) > 0
    ? <<-EOT
      mkdir -p /etc/gitlab-runner/certs/
      cat <<- EOF > /etc/gitlab-runner/certs/ca.crt
      ${var.runners_ca_certificate}
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
    length(var.runners_gitlab_certificate) + length(var.runners_ca_certificate) > 0
    ? join("\n", [
      local.pre_install_gitlab_certificate,
      local.pre_install_ca_certificate,
      local.pre_install_certificates_end
    ])
    : ""
  )

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

  runners_machine_autoscaling = templatefile("${path.module}/template/runners_machine_autoscaling.tftpl", {
    runners_machine_autoscaling = var.runners_machine_autoscaling
    }
  )

  runners_docker_services = templatefile("${path.module}/template/runners_docker_services.tftpl", {
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

resource "local_file" "config_toml" {
  content  = local.template_runner_config
  filename = "${path.module}/debug/runner_config.toml"
}

resource "local_file" "user_data" {
  count    = var.show_user_data_in_plan ? 1 : 0
  content  = nonsensitive(local.template_user_data)
  filename = "${path.module}/debug/user_data.sh"
}

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

  # Define key for runner token for SSM
  secure_parameter_store_runner_token_key  = "${var.environment}-${var.runner_gitlab_token_secure_parameter_store}"
  secure_parameter_store_runner_sentry_dsn = "${var.environment}-${var.runner_sentry_secure_parameter_store_name}"

  # Custom names for runner agent instance, security groups, and IAM objects
  name_runner_agent_instance = var.runner_instance.name_prefix == null ? local.tags["Name"] : var.runner_instance.name_prefix
  name_sg                    = var.security_group_prefix == "" ? local.tags["Name"] : var.security_group_prefix
  name_iam_objects           = var.iam_object_prefix == "" ? local.tags["Name"] : var.iam_object_prefix

  runner_worker_graceful_terminate_heartbeat_timeout = (var.runner_terminate_ec2_lifecycle_timeout_duration == null
    ? min(7200, tonumber(coalesce(var.runner_gitlab_registration_config.maximum_timeout, 0)) + 300)
  : var.runner_terminate_ec2_lifecycle_timeout_duration)

  kms_key_arn = local.provided_kms_key == "" && var.enable_managed_kms_key ? aws_kms_key.default[0].arn : local.provided_kms_key
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

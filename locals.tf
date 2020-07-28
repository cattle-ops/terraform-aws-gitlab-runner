locals {
  // Convert list to a string separated and prepend by a comma
  docker_machine_options_string = format(
    ",%s",
    join(",", formatlist("%q", var.docker_machine_options)),
  )

  // convert the options for the session server
  session_server_string = join("", formatlist("%s", ["[session_server]",
                                            format("listen_address = %q", var.session_server_listen_address),
                                            format("advertise_address = %q", var.session_server_advertise_address),
                                            format("session_timeout = %s", var.session_server_session_timeout)]))

  // Ensure off peak is optional
  runners_off_peak_periods_string = var.runners_off_peak_periods == "" ? "" : format("OffPeakPeriods = %s", var.runners_off_peak_periods)

  // Ensure max builds is optional
  runners_max_builds_string = var.runners_max_builds == 0 ? "" : format("MaxBuilds = %d", var.runners_max_builds)

  // Define key for runner token for SSM
  secure_parameter_store_runner_token_key = "${var.environment}-${var.secure_parameter_store_runner_token_key}"

  // custom names for instances and security groups
  name_runner_agent_instance = var.overrides["name_runner_agent_instance"] == "" ? local.tags["Name"] : var.overrides["name_runner_agent_instance"]
  name_sg                    = var.overrides["name_sg"] == "" ? local.tags["Name"] : var.overrides["name_sg"]
  runners_additional_volumes = <<-EOT
  %{~for volume in var.runners_additional_volumes~},"${volume}"%{endfor~}
  EOT
}

locals {
  // Check if the desired region is located within china and adapt the policies folder accordingly
  policy_folder = (contains(["cn-northwest-1", "cn-north-1"], var.aws_region) ? "policies-cn-regions" : "policies")

  // Convert list to a string separated and prepend by a comma
  docker_machine_options_string = format(
    ",%s",
    join(",", formatlist("%q", var.docker_machine_options)),
  )

  // Ensure off peak is optional
  runners_off_peak_periods_string = var.runners_off_peak_periods == "" ? "" : format("OffPeakPeriods = %s", var.runners_off_peak_periods)

  // Define key for runner token for SSM
  secure_parameter_store_runner_token_key = "${var.environment}-${var.secure_parameter_store_runner_token_key}"

  // custom names for instances and security groups
  name_runner_instance       = var.overrides["name_runner_agent_instance"] == "" ? local.tags["Name"] : var.overrides["name_runner_agent_instance"]
  name_sg                    = var.overrides["name_sg"] == "" ? local.tags["Name"] : var.overrides["name_sg"]
  runners_additional_volumes = <<-EOT
  %{~for volume in var.runners_additional_volumes~},"${volume}"%{endfor~}
  EOT
}

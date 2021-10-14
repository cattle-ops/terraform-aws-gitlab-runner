locals {
  // Convert list to a string separated and prepend by a comma
  docker_machine_options_string = format(
    ",%s",
    join(",", formatlist("%q", var.docker_machine_options)),
  )

  // Ensure max builds is optional
  runners_max_builds_string = var.runners_max_builds == 0 ? "" : format("MaxBuilds = %d", var.runners_max_builds)

  // Define key for runner token for SSM
  secure_parameter_store_runner_token_key  = "${var.environment}-${var.secure_parameter_store_runner_token_key}"
  secure_parameter_store_runner_sentry_dsn = "${var.environment}-${var.secure_parameter_store_runner_sentry_dsn}"

  // custom names for instances and security groups
  name_runner_agent_instance = var.overrides["name_runner_agent_instance"] == "" ? local.tags["Name"] : var.overrides["name_runner_agent_instance"]
  name_sg                    = var.overrides["name_sg"] == "" ? local.tags["Name"] : var.overrides["name_sg"]
  name_iam_objects           = var.overrides["name_iam_objects"] == "" ? local.tags["Name"] : var.overrides["name_iam_objects"]
  runners_additional_volumes = <<-EOT
  %{~for volume in var.runners_additional_volumes~},"${volume}"%{endfor~}
  EOT

  runners_machine_autoscaling = templatefile("${path.module}/template/runners_machine_autoscaling.tpl", {
    runners_machine_autoscaling = var.runners_machine_autoscaling
    }
  )

  docker_machine_spot_price_bid = var.docker_machine_spot_price_bid == "up-to-on-demand" ? tonumber(values(values(jsondecode(data.aws_pricing_product.ec2_docker_machine.result).terms.OnDemand)[0].priceDimensions)[0].pricePerUnit.USD) : var.docker_machine_spot_price_bid

  // Depcrecated off peak, ensure not set if not explicit set.
  runners_off_peak_periods_string = var.runners_off_peak_periods == null ? "" : format("OffPeakPeriods = %s", var.runners_off_peak_periods)
  runners_off_peak_timezone       = var.runners_off_peak_timezone == null ? "" : "OffPeakTimezone = \"${var.runners_off_peak_timezone}\""
  runners_off_peak_idle_count     = var.runners_off_peak_idle_count == -1 ? "" : format("OffPeakIdleCount = %d", var.runners_off_peak_idle_count)
  runners_off_peak_idle_time      = var.runners_off_peak_idle_time == -1 ? "" : format("OffPeakIdleTime = %d", var.runners_off_peak_idle_time)

}

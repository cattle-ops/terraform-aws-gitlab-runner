locals {
  tags_merged = merge(
    {
      "Name" = format("%s", var.environment)
    },
    {
      "Environment" = format("%s", var.environment)
    },
    var.tags,
  )

  tags = { for k, v in local.tags_merged : k => v if !contains(var.suppressed_tags, k) }

  agent_tags_merged = merge(
    {
      # false positive: TfLint fails with: Call to function "format" failed: unsupported value for "%s" at 0: null value cannot be formatted.
      # tflint-ignore: aws_iam_policy_sid_invalid_characters
      "Name" = format("%s", local.name_runner_agent_instance)
    },
    {
      "Environment" = format("%s", var.environment)
    },
    var.tags,
    var.runner_instance.additional_tags
  )

  agent_tags = { for k, v in local.agent_tags_merged : k => v if !contains(var.suppressed_tags, k) }

  runner_tags_merged = merge(
    local.tags,
    var.runner_worker_docker_machine_role.additional_tags,
    # overwrites the `Name` key from `local.tags`
    var.runner_worker_docker_machine_instance.name_prefix == "" ? { Name = substr(format("%s", var.environment), 0, 16) } : { Name = var.runner_worker_docker_machine_instance.name_prefix },
  )
}

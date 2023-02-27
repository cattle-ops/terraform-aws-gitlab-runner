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
      "Name" = format("%s", local.name_runner_agent_instance)
    },
    {
      "Environment" = format("%s", var.environment)
    },
    var.tags,
    var.agent_tags
  )

  agent_tags = { for k, v in local.agent_tags_merged : k => v if !contains(var.suppressed_tags, k) }

  runner_tags_merged = merge(
    local.tags,
    var.runner_tags,
    # overwrites the `Name` key from `local.tags`
    var.overrides["name_docker_machine_runners"] == "" ? { Name = substr(format("%s", var.environment), 0, 16) } : { Name = var.overrides["name_docker_machine_runners"] },
  )

  # remove the `Name` tag in addition if docker+machine adds one to avoid a failure due to a duplicate `Name` tag
  runner_tags = local.docker_machine_adds_name_tag ? { for k, v in local.runner_tags_merged : k => v if !contains(concat(var.suppressed_tags, ["Name"]), k) } : local.runner_tags_merged

  runner_tags_string = join(",", flatten([
    for key in keys(local.runner_tags) : [key, lookup(local.runner_tags, key)]
  ]))
}

locals {
  tags = merge(
    {
      "Name" = format("%s", var.environment)
    },
    {
      "Environment" = format("%s", var.environment)
    },
    var.tags,
  )

  agent_tags = merge(
    {
      "Name" = format("%s", local.name_runner_agent_instance)
    },
    {
      "Environment" = format("%s", var.environment)
    },
    var.tags,
    var.agent_tags
  )

  runner_tags_merged = merge(
    local.tags,
    var.runner_tags,
    # overwrites the `Name` key from `local.tags`
    var.overrides["name_docker_machine_runners"] == "" ? { Name = substr(format("%s", var.environment), 0, 16) } : { Name = var.overrides["name_docker_machine_runners"] },
  )

  # remove the `Name` tag if docker+machine adds one to avoid a failure due to a duplicate `Name` tag
  runner_tags = local.docker_machine_adds_name_tag ? { for k, v in local.runner_tags_merged : k => v if k != "Name" } : local.runner_tags_merged

  tags_string = join(",", flatten([
    for key in keys(local.tags) : [key, lookup(local.tags, key)]
  ]))

  runner_tags_string = join(",", flatten([
    for key in keys(local.runner_tags) : [key, lookup(local.runner_tags, key)]
  ]))
}

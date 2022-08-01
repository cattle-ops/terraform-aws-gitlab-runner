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

  runner_tags = merge(
    !local.docker_machine_adds_name_tag ?
    var.overrides["name_docker_machine_runners"] == "" ? { Name = format("%s-docker-machine", var.environment) } : { Name = var.overrides["name_docker_machine_runners"] }
    : {},
    var.runner_tags
  )

  tags_string = join(",", flatten([
    for key in keys(local.tags) : [key, lookup(local.tags, key)]
  ]))

  runner_tags_string = join(",", flatten([
    for key in keys(local.runner_tags) : [key, lookup(local.runner_tags, key)]
  ]))
}

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

  tags_string = join(",", flatten([
    for key in keys(local.tags) : [key, lookup(local.tags, key)]
  ]))

  runner_tags_string = join(",", flatten([
    for key in keys(var.runner_tags) : [key, lookup(var.runner_tags, key)]
  ]))
}

data "null_data_source" "tags" {
  count = length(local.tags)

  inputs = {
    key                 = element(keys(local.tags), count.index)
    value               = element(values(local.tags), count.index)
    propagate_at_launch = "true"
  }
}


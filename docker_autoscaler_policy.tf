resource "aws_iam_role" "docker_autoscaler" {
  count                = var.runner_worker.type == "docker-autoscaler" ? 1 : 0
  name                 = "${local.name_iam_objects}-docker-autoscaler"
  assume_role_policy   = length(var.runner_worker_docker_autoscaler_role.assume_role_policy_json) > 0 ? var.runner_worker_docker_autoscaler_role.assume_role_policy_json : templatefile("${path.module}/policies/instance-role-trust-policy.json", {})
  permissions_boundary = var.iam_permissions_boundary == "" ? null : "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:policy/${var.iam_permissions_boundary}"

  tags = merge(local.tags, var.runner_worker_docker_autoscaler_role.additional_tags)
}

resource "aws_iam_policy" "instance_docker_autoscaler_policy" {
  count = var.runner_worker.type == "docker-autoscaler" && var.runner_role.create_role_profile ? 1 : 0

  name        = "${local.name_iam_objects}-docker-autoscaler"
  path        = "/"
  description = "Policy for docker autoscaler."
  # see https://gitlab.com/gitlab-org/fleeting/plugins/aws#recommended-iam-policy for needed policies
  policy = templatefile("${path.module}/policies/instance-docker-autoscaler-policy.json",
    {
      aws_region          = data.aws_region.current.name
      partition           = data.aws_partition.current.partition
      autoscaler_asg_arn  = aws_autoscaling_group.autoscaler[0].arn
      autoscaler_asg_name = aws_autoscaling_group.autoscaler[0].name
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "instance_docker_autoscaler_policy" {
  count = var.runner_worker.type == "docker-autoscaler" && var.runner_role.create_role_profile ? 1 : 0

  role       = aws_iam_role.instance[0].name
  policy_arn = aws_iam_policy.instance_docker_autoscaler_policy[0].arn
}

resource "aws_iam_role_policy_attachment" "docker_autoscaler_user_defined_policies" {
  count = var.runner_worker.type == "docker-autoscaler" ? length(var.runner_worker_docker_autoscaler_role.policy_arns) : 0

  role       = aws_iam_role.docker_autoscaler[0].name
  policy_arn = var.runner_worker_docker_autoscaler_role.policy_arns[count.index]
}

resource "aws_iam_role_policy_attachment" "docker_autoscaler_session_manager_aws_managed" {
  count = (var.runner_worker.type == "docker-autoscaler" && var.runner_worker.ssm_access) ? 1 : 0

  role       = aws_iam_role.docker_autoscaler[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

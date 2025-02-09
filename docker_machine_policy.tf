################################################################################
### docker machine instance policy
################################################################################
resource "aws_iam_role" "docker_machine" {
  count                = var.runner_worker.type == "docker+machine" ? 1 : 0
  name                 = "${local.name_iam_objects}-docker-machine"
  assume_role_policy   = length(var.runner_worker_docker_machine_role.assume_role_policy_json) > 0 ? var.runner_worker_docker_machine_role.assume_role_policy_json : templatefile("${path.module}/policies/instance-role-trust-policy.json", {})
  permissions_boundary = var.iam_permissions_boundary == "" ? null : "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:policy/${var.iam_permissions_boundary}"

  tags = merge(local.tags, var.runner_worker_docker_machine_role.additional_tags)
}

################################################################################
### Policies for runner agent instance to create docker machines via spot req.
###
### iam:PassRole To pass the role from the agent to the docker machine runners
################################################################################
resource "aws_iam_policy" "instance_docker_machine_policy" {
  count = var.runner_worker.type == "docker+machine" && var.runner_role.create_role_profile ? 1 : 0

  name        = "${local.name_iam_objects}-docker-machine"
  path        = "/"
  description = "Policy for docker machine."
  policy = templatefile("${path.module}/policies/instance-docker-machine-policy.json",
    {
      docker_machine_role_arn = aws_iam_role.docker_machine[0].arn
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "instance_docker_machine_policy" {
  count = var.runner_worker.type == "docker+machine" && var.runner_role.create_role_profile ? 1 : 0

  role       = aws_iam_role.instance[0].name
  policy_arn = aws_iam_policy.instance_docker_machine_policy[0].arn
}

################################################################################
### Add user defined policies
################################################################################
resource "aws_iam_role_policy_attachment" "docker_machine_user_defined_policies" {
  count = var.runner_worker.type == "docker+machine" ? length(var.runner_worker_docker_machine_role.policy_arns) : 0

  role       = aws_iam_role.docker_machine[0].name
  policy_arn = var.runner_worker_docker_machine_role.policy_arns[count.index]
}

resource "aws_iam_role_policy_attachment" "docker_machine_session_manager_aws_managed" {
  count = (var.runner_worker.type == "docker+machine" && var.runner_worker.ssm_access) ? 1 : 0

  role       = aws_iam_role.docker_machine[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

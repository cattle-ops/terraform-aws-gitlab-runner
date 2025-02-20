resource "aws_iam_instance_profile" "docker_machine" {
  count = var.runner_worker.type == "docker+machine" ? 1 : 0
  name  = "${local.name_iam_objects}-docker-machine"
  role  = aws_iam_role.docker_machine[0].name
  tags  = local.tags
}

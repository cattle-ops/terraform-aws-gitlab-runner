data "template_file" "instance_profile" {
  count    = var.enable_cloudwatch_logging ? 1 : 0
  template = (contains(["cn-northwest-1", "cn-north-1"], var.aws_region) ? file("${path.module}/policies-cn-regions/instance-logging-policy.json") : file("${path.module}/policies/instance-logging-policy.json"))
}

resource "aws_iam_role_policy" "instance" {
  count  = var.enable_cloudwatch_logging ? 1 : 0
  name   = "${var.environment}-instance-role"
  role   = aws_iam_role.instance.name
  policy = data.template_file.instance_profile[0].rendered
}

resource "aws_cloudwatch_log_group" "environment" {
  count = var.enable_cloudwatch_logging ? 1 : 0
  name  = var.environment

  tags = local.tags
}


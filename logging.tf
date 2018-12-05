data "template_file" "instance_profile" {
  count    = "${var.enable_cloudwatch_logging ? 1 : 0}"
  template = "${file("${path.module}/policies/instance-logging-policy.json")}"
  vars {
    bucket_name = "${var.bucket_name_runner_roken_cache}"
    bucket_key = "${var.bucket_key_runner_token_cache}"
  }
}

resource "aws_iam_role_policy" "instance" {
  count  = "${var.enable_cloudwatch_logging ? 1 : 0}"
  name   = "${var.environment}-instance-role"
  role   = "${aws_iam_role.instance.name}"
  policy = "${data.template_file.instance_profile.rendered}"
}

resource "aws_cloudwatch_log_group" "environment" {
  count = "${var.enable_cloudwatch_logging ? 1 : 0}"
  name  = "${var.environment}"
  tags = "${local.tags}"
}

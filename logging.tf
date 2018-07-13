data "template_file" "instance_profile" {
  count    = "${var.enable_cloudwatch_logging ? 1 : 0}"
  template = "${file("${path.module}/policies/instance-profile-policy.json")}"
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

  tags {
    Name        = "${var.environment}-runners"
    Environment = "${var.environment}"
  }
}

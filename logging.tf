data "template_file" "instance_profile" {
  template = "${file("${path.module}/policies/instance-profile-policy.json")}"
}

resource "aws_iam_role_policy" "instance" {
  name   = "${var.environment}-instance-role"
  role   = "${aws_iam_role.instance.name}"
  policy = "${data.template_file.instance_profile.rendered}"
}

resource "aws_cloudwatch_log_group" "environment" {
  name = "${var.environment}"

  tags {
    Name        = "${var.environment}-runners"
    Environment = "${var.environment}"
  }
}

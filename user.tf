resource "aws_iam_user" "docker_machine_user" {
  name = "${var.environment}-${var.docker_machine_user}"
}

resource "aws_iam_access_key" "docker_machine_user" {
  user = "${aws_iam_user.docker_machine_user.name}"
}

data "aws_iam_policy_document" "policy" {
  statement {
    actions = [
      "ec2:*",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy_attachment" "policy" {
  name       = "${var.environment}-policy"
  policy_arn = "${aws_iam_policy.policy.arn}"

  users = [
    "${aws_iam_user.docker_machine_user.name}",
  ]
}

resource "aws_iam_policy" "policy" {
  name   = "${var.environment}-policy"
  policy = "${data.aws_iam_policy_document.policy.json}"
}

resource "aws_key_pair" "key" {
  key_name   = "${var.environment}-gitlab-runner"
  public_key = "${file("${var.ssh_key_file_pub}")}"
}

resource "aws_security_group" "runner" {
  name_prefix = "${var.environment}-security-group"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name        = "${var.environment}-runner-sg"
    Environment = "${var.environment}"
  }
}

resource "aws_security_group" "docker_machine" {
  name_prefix = "${var.environment}-docker-machine"
  vpc_id      = "${var.vpc_id}"

  tags {
    Name        = "${var.environment}-gitlab-sg"
    Environment = "${var.environment}"
  }
}

resource "aws_security_group_rule" "docker" {
  type        = "ingress"
  from_port   = 2376
  to_port     = 2376
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.docker_machine.id}"
}

resource "aws_security_group_rule" "ssh" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.docker_machine.id}"
}

resource "aws_security_group_rule" "out_all" {
  type        = "egress"
  from_port   = 0
  to_port     = 65535
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.docker_machine.id}"
}

data "template_file" "runners" {
  template = "${file("${path.module}/template/runner.tpl")}"

  vars {
    aws_region = "${var.aws_region}"
    gitlab_url = "${var.runners_gitlab_url}"

    runners_vpc_id              = "${var.vpc_id}"
    runners_subnet_id           = "${var.subnet_id_runners}"
    runners_instance_type       = "${var.docker_machine_instance_type}"
    runners_spot_price_bid      = "${var.docker_machine_spot_price_bid}"
    runners_access_key          = "${aws_iam_access_key.docker_machine_user.id}"
    runners_secret_key          = "${aws_iam_access_key.docker_machine_user.secret}"
    runners_security_group_name = "${aws_security_group.docker_machine.name}"

    runners_name           = "${var.runners_name}"
    runners_token          = "${var.runners_token}"
    runners_limit          = "${var.runners_limit}"
    runners_concurrent     = "${var.runners_concurrent}"
    runners_privilled      = "${var.runners_privilled}"
    runners_idle_count     = "${var.runners_idle_count}"
    runners_idle_time      = "${var.runners_idle_time}"
    bucket_user_access_key = "${aws_iam_access_key.cache_user.id}"
    bucket_user_secret_key = "${aws_iam_access_key.cache_user.secret}"
    bucket_name            = "${aws_s3_bucket.build_cache.bucket}"
  }
}

data "template_file" "user_data" {
  template = "${file("${path.module}/template/user-data.tpl")}"

  vars {
    runners_config = "${data.template_file.runners.rendered}"
    logging        = "${data.template_file.logging.rendered}"
  }
}

data "template_file" "logging" {
  template = "${file("${path.module}/template/logging.tpl")}"

  vars {
    environment = "${var.environment}"
  }
}

resource "aws_autoscaling_group" "gitlab_runner_instance" {
  name                = "${var.environment}-as-group"
  vpc_zone_identifier = ["${var.subnet_id_gitlab_runner}"]

  # vpc_zone_identifier       = ["${var.subnets}"]
  min_size                  = "1"
  max_size                  = "1"
  desired_capacity          = "1"
  health_check_grace_period = 0
  launch_configuration      = "${aws_launch_configuration.gitlab_runner_instance.name}"

  tag {
    key                 = "Name"
    value               = "${var.environment}-gitlab-runner"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "${var.environment}"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "gitlab_runner_instance" {
  security_groups      = ["${aws_security_group.runner.id}"]
  key_name             = "${aws_key_pair.key.key_name}"
  image_id             = "${lookup(var.amazon_optimized_amis, var.aws_region)}"
  user_data            = "${data.template_file.user_data.rendered}"
  instance_type        = "${var.instance_type}"
  iam_instance_profile = "${aws_iam_instance_profile.instance.name}"

  # associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_instance_profile" "instance" {
  name = "${var.environment}-instance-profile"
  role = "${aws_iam_role.instance.name}"
}

data "template_file" "instance_role_trust_policy" {
  template = "${file("${path.module}/policies/instance-role-trust-policy.json")}"
}

resource "aws_iam_role" "instance" {
  name               = "${var.environment}-instance-role"
  assume_role_policy = "${data.template_file.instance_role_trust_policy.rendered}"
}

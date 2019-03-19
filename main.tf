resource "aws_key_pair" "key" {
  key_name   = "${var.environment}-gitlab-runner"
  public_key = "${var.ssh_public_key}"
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

  tags = "${local.tags}"
}

resource "aws_security_group" "docker_machine" {
  name_prefix = "${var.environment}-docker-machine"
  vpc_id      = "${var.vpc_id}"

  tags = "${local.tags}"
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

data "template_file" "user_data" {
  template = "${file("${path.module}/template/user-data.tpl")}"

  vars {
    logging       = "${var.enable_cloudwatch_logging ? data.template_file.logging.rendered : ""}"
    gitlab_runner = "${data.template_file.gitlab_runner.rendered}"
  }
}

data "template_file" "logging" {
  template = "${file("${path.module}/template/logging.tpl")}"

  vars {
    environment = "${var.environment}"
  }
}

data "template_file" "gitlab_runner" {
  template = "${file("${path.module}/template/gitlab-runner.tpl")}"

  vars {
    gitlab_runner_version  = "${var.gitlab_runner_version}"
    docker_machine_version = "${var.docker_machine_version}"
    runners_config         = "${data.template_file.runners.rendered}"
    runners_executor       = "${var.runners_executor}"
    pre_install            = "${var.userdata_pre_install}"
    post_install           = "${var.userdata_post_install}"
  }
}

locals {
  // Convert list to a string seperated and prepend by a comma
  docker_machine_options_string   = "${format(",%s", join(",", formatlist("%q", var.docker_machine_options)))}"
  runners_off_peak_periods_string = "${var.runners_off_peak_periods == "" ? "" : format("OffPeakPeriods = %s", var.runners_off_peak_periods)}"
}

data "template_file" "runners" {
  template = "${file("${path.module}/template/runner-config.tpl")}"

  vars {
    aws_region = "${var.aws_region}"
    gitlab_url = "${var.runners_gitlab_url}"

    runners_vpc_id                    = "${var.vpc_id}"
    runners_subnet_id                 = "${var.subnet_id_runners}"
    runners_aws_zone                  = "${var.aws_zone}"
    runners_instance_type             = "${var.docker_machine_instance_type}"
    runners_spot_price_bid            = "${var.docker_machine_spot_price_bid}"
    runners_security_group_name       = "${aws_security_group.docker_machine.name}"
    runners_monitoring                = "${var.runners_monitoring}"
    docker_machine_options            = "${length(var.docker_machine_options) == 0 ? "" : local.docker_machine_options_string}"
    runners_name                      = "${var.runners_name}"
    runners_tags                      = "${local.tags_string}"
    runners_token                     = "${var.runners_token}"
    runners_executor                  = "${var.runners_executor}"
    runners_limit                     = "${var.runners_limit}"
    runners_concurrent                = "${var.runners_concurrent}"
    runners_image                     = "${var.runners_image}"
    runners_privilled                 = "${var.runners_privilled}"
    runners_idle_count                = "${var.runners_idle_count}"
    runners_idle_time                 = "${var.runners_idle_time}"
    runners_off_peak_timezone         = "${var.runners_off_peak_timezone}"
    runners_off_peak_idle_count       = "${var.runners_off_peak_idle_count}"
    runners_off_peak_idle_time        = "${var.runners_off_peak_idle_time}"
    runners_off_peak_periods_string   = "${local.runners_off_peak_periods_string}"
    runners_root_size                 = "${var.runners_root_size}"
    runners_iam_instance_profile_name = "${var.runners_iam_instance_profile_name}"
    runners_use_private_address       = "${var.runners_use_private_address}"
    runners_pre_build_script          = "${var.runners_pre_build_script}"
    runners_post_build_script         = "${var.runners_post_build_script}"
    runners_pre_clone_script          = "${var.runners_pre_clone_script}"
    runners_request_concurrency       = "${var.runners_request_concurrency}"
    runners_output_limit              = "${var.runners_output_limit}"
    bucket_name                       = "${aws_s3_bucket.build_cache.bucket}"
    shared_cache                      = "${var.cache_shared}"
  }
}

resource "aws_autoscaling_group" "gitlab_runner_instance" {
  name                = "${var.environment}-as-group"
  vpc_zone_identifier = ["${var.subnet_ids_gitlab_runner}"]

  # vpc_zone_identifier       = ["${var.subnets}"]
  min_size                  = "1"
  max_size                  = "1"
  desired_capacity          = "1"
  health_check_grace_period = 0
  launch_configuration      = "${aws_launch_configuration.gitlab_runner_instance.name}"

  tags = ["${data.null_data_source.tags.*.outputs}"]
}

data "aws_ami" "runner" {
  most_recent = "true"

  filter = "${var.ami_filter}"

  owners = ["${var.ami_owners}"]
}

resource "aws_launch_configuration" "gitlab_runner_instance" {
  security_groups      = ["${aws_security_group.runner.id}"]
  key_name             = "${aws_key_pair.key.key_name}"
  image_id             = "${data.aws_ami.runner.id}"
  user_data            = "${data.template_file.user_data.rendered}"
  instance_type        = "${var.instance_type}"
  iam_instance_profile = "${aws_iam_instance_profile.instance.name}"

  associate_public_ip_address = false

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
### Trust policy
################################################################################
resource "aws_iam_instance_profile" "instance" {
  name = "${var.environment}-instance-profile"
  role = "${aws_iam_role.instance.name}"
}

data "template_file" "instance_role_trust_policy" {
  template = "${length(var.instance_role_json) > 0 ? var.instance_role_json : file("${path.module}/policies/instance-role-trust-policy.json")}"
}

resource "aws_iam_role" "instance" {
  name               = "${var.environment}-instance-role"
  assume_role_policy = "${data.template_file.instance_role_trust_policy.rendered}"
}

################################################################################
### docker machine instance policy
################################################################################
data "template_file" "docker_machine_policy" {
  template = "${file("${path.module}/policies/instance-docker-machine-policy.json")}"
}

resource "aws_iam_policy" "docker_machine" {
  name        = "${var.environment}-docker-machine"
  path        = "/"
  description = "Policy for docker machine."

  policy = "${data.template_file.docker_machine_policy.rendered}"
}

resource "aws_iam_role_policy_attachment" "docker_machine" {
  role       = "${aws_iam_role.instance.name}"
  policy_arn = "${aws_iam_policy.docker_machine.arn}"
}

################################################################################
### docker machine policy to access the shared cache
################################################################################
data "template_file" "docker_machine_cache_policy" {
  template = "${file("${path.module}/policies/cache.json")}"

  vars {
    s3_cache_arn = "${aws_s3_bucket.build_cache.arn}"
  }
}

resource "aws_iam_policy" "docker_machine_cache" {
  name        = "${var.environment}-docker-machine-cache"
  path        = "/"
  description = "Policy for docker machine instance to access cache"

  policy = "${data.template_file.docker_machine_cache_policy.rendered}"
}

resource "aws_iam_role_policy_attachment" "docker_machine_cache" {
  role       = "${aws_iam_role.instance.name}"
  policy_arn = "${aws_iam_policy.docker_machine_cache.arn}"
}

################################################################################
### Service linked policy, optional
################################################################################
data "template_file" "service_linked_role" {
  count = "${var.allow_iam_service_linked_role_creation ? 1 : 0}"

  template = "${file("${path.module}/policies/service-linked-role-create-policy.json")}"
}

resource "aws_iam_policy" "service_linked_role" {
  count = "${var.allow_iam_service_linked_role_creation ? 1 : 0}"

  name        = "${var.environment}-service_linked_role"
  path        = "/"
  description = "Policy for creation of service linked roles."

  policy = "${data.template_file.service_linked_role.rendered}"
}

resource "aws_iam_role_policy_attachment" "service_linked_role" {
  count = "${var.allow_iam_service_linked_role_creation ? 1 : 0}"

  role       = "${aws_iam_role.instance.name}"
  policy_arn = "${aws_iam_policy.service_linked_role.arn}"
}

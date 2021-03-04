data "aws_caller_identity" "current" {}

data "aws_subnet" "runners" {
  id = var.subnet_id_runners
}

data "aws_availability_zone" "runners" {
  name = data.aws_subnet.runners.availability_zone
}

# Parameter value is managed by the user-data script of the gitlab runner instance
resource "aws_ssm_parameter" "runner_registration_token" {
  name  = local.secure_parameter_store_runner_token_key
  type  = "SecureString"
  value = "null"

  tags = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "null_resource" "remove_runner" {
  depends_on = [aws_ssm_parameter.runner_registration_token]
  triggers = {
    script                                  = "${path.module}/bin/remove-runner.sh"
    aws_region                              = var.aws_region
    runners_gitlab_url                      = var.runners_gitlab_url
    secure_parameter_store_runner_token_key = local.secure_parameter_store_runner_token_key
  }

  provisioner "local-exec" {
    when       = destroy
    on_failure = continue
    command    = "${self.triggers.script} ${self.triggers.aws_region} ${self.triggers.runners_gitlab_url} ${self.triggers.secure_parameter_store_runner_token_key}"
  }
}

locals {
  enable_asg_recreation = var.enable_forced_updates != null ? ! var.enable_forced_updates : var.enable_asg_recreation

  template_user_data = templatefile("${path.module}/template/user-data.tpl",
    {
      aws_cli_version          = "2.0.30"
      eip                      = var.enable_eip ? local.template_eip : ""
      logging                  = var.enable_cloudwatch_logging ? local.logging_user_data : ""
      gitlab_runner            = local.template_gitlab_runner
      extra_files_sync_command = module.config.extra_files_sync_command
      user_data_trace_log      = var.enable_runner_user_data_trace_log
  })

  template_eip = templatefile("${path.module}/template/eip.tpl", {
    eip = join(",", aws_eip.gitlab_runner.*.public_ip)
  })

  template_gitlab_runner = templatefile("${path.module}/template/gitlab-runner.tpl",
    {
      gitlab_runner_version                   = var.gitlab_runner_version
      docker_machine_version                  = var.docker_machine_version
      docker_machine_download_url             = var.docker_machine_download_url
      runners_config_s3_uri                   = module.config.config_uri
      runners_executor                        = var.runners_executor
      pre_install                             = var.userdata_pre_install
      post_install                            = var.userdata_post_install
      runners_gitlab_url                      = var.runners_gitlab_url
      runners_token                           = var.runners_token
      secure_parameter_store_runner_token_key = local.secure_parameter_store_runner_token_key
      secure_parameter_store_region           = var.aws_region
      gitlab_runner_registration_token        = var.gitlab_runner_registration_config["registration_token"]
      giltab_runner_description               = var.gitlab_runner_registration_config["description"]
      gitlab_runner_tag_list                  = var.gitlab_runner_registration_config["tag_list"]
      gitlab_runner_locked_to_project         = var.gitlab_runner_registration_config["locked_to_project"]
      gitlab_runner_run_untagged              = var.gitlab_runner_registration_config["run_untagged"]
      gitlab_runner_maximum_timeout           = var.gitlab_runner_registration_config["maximum_timeout"]
      gitlab_runner_access_level              = lookup(var.gitlab_runner_registration_config, "access_level", "not_protected")
  })

  runners_defaults = {
    machine_driver = var.docker_machine_driver
    machine_name   = var.docker_machine_name
    aws_region     = var.aws_region
    gitlab_url     = var.runners_gitlab_url
    name           = var.runners_name
    tags = replace(var.overrides["name_docker_machine_runners"] == "" ? format(
      var.runners_token,
      "Name,%s-docker-machine,%s,%s",
      var.environment,
      local.tags_string,
      local.runner_tags_string,
      ) : format(
      "%s,%s,Name,%s",
      local.tags_string,
      local.runner_tags_string,
      var.overrides["name_docker_machine_runners"],
    ), ",,", ",")
    vpc_id                    = var.vpc_id
    subnet_id                 = var.subnet_id_runners
    aws_zone                  = data.aws_availability_zone.runners.name_suffix
    instance_type             = var.docker_machine_instance_type
    spot_price_bid            = var.docker_machine_spot_price_bid
    ami                       = data.aws_ami.docker_machine.id
    security_group_name       = aws_security_group.docker_machine.name
    monitoring                = var.runners_monitoring
    ebs_optimized             = var.runners_ebs_optimized
    instance_profile          = aws_iam_instance_profile.docker_machine.name
    additional_volumes        = local.runners_additional_volumes
    token                     = var.runners_token
    executor                  = var.runners_executor
    limit                     = var.runners_limit
    image                     = var.runners_image
    privileged                = var.runners_privileged
    docker_runtime            = var.runners_docker_runtime
    helper_image              = var.runners_helper_image
    machine_autoscaling       = local.runners_machine_autoscaling
    shm_size                  = var.runners_shm_size
    pull_policy               = var.runners_pull_policy
    idle_count                = var.runners_idle_count
    idle_time                 = var.runners_idle_time
    max_builds                = local.runners_max_builds_string
    off_peak_timezone         = var.runners_off_peak_timezone
    off_peak_idle_count       = var.runners_off_peak_idle_count
    off_peak_idle_time        = var.runners_off_peak_idle_time
    off_peak_periods_string   = local.runners_off_peak_periods_string
    root_size                 = var.runners_root_size
    iam_instance_profile_name = var.runners_iam_instance_profile_name
    use_private_address_only  = var.runners_use_private_address
    use_private_address       = ! var.runners_use_private_address
    request_spot_instance     = var.runners_request_spot_instance
    environment_vars          = jsonencode(var.runners_environment_vars)
    pre_build_script          = var.runners_pre_build_script
    post_build_script         = var.runners_post_build_script
    pre_clone_script          = var.runners_pre_clone_script
    request_concurrency       = var.runners_request_concurrency
    output_limit              = var.runners_output_limit
    volumes_tmpfs             = join(",", [for v in var.runners_volumes_tmpfs : format("\"%s\" = \"%s\"", v["volume"], v["options"])])
    services_volumes_tmpfs    = join(",", [for v in var.runners_services_volumes_tmpfs : format("\"%s\" = \"%s\"", v["volume"], v["options"])])
    docker_machine_options    = local.docker_machine_options_string
    bucket_name               = local.bucket_name
    shared_cache              = var.cache_shared
  }

  template_runner_config_header = templatefile("${path.module}/template/runner-config-header.tpl", {
    runners_concurrent = var.runners_concurrent
  })

  template_runner_config_runners = join("\n", [
    for runner in var.runners :
    templatefile("${path.module}/template/runner-config-runners.tpl", merge(local.runners_defaults, runner))
  ])

  runner_config = <<-EOF
    ${local.template_runner_config_header}
    ${local.template_runner_config_runners}
  EOF
}

data "aws_ami" "docker_machine" {
  most_recent = "true"

  dynamic "filter" {
    for_each = var.runner_ami_filter
    content {
      name   = filter.key
      values = filter.value
    }
  }

  owners = var.runner_ami_owners
}

resource "aws_autoscaling_group" "gitlab_runner_instance" {
  name                      = local.enable_asg_recreation ? "${aws_launch_configuration.gitlab_runner_instance.name}-asg" : "${var.environment}-as-group"
  vpc_zone_identifier       = var.subnet_ids_gitlab_runner
  min_size                  = "1"
  max_size                  = "1"
  desired_capacity          = "1"
  health_check_grace_period = 0
  launch_configuration      = aws_launch_configuration.gitlab_runner_instance.name
  enabled_metrics           = var.metrics_autoscaling
  tags                      = data.null_data_source.agent_tags.*.outputs
  timeouts {
    delete = var.asg_delete_timeout
  }
}

resource "aws_autoscaling_schedule" "scale_in" {
  count                  = var.enable_schedule ? 1 : 0
  autoscaling_group_name = aws_autoscaling_group.gitlab_runner_instance.name
  scheduled_action_name  = "scale_in-${aws_autoscaling_group.gitlab_runner_instance.name}"
  recurrence             = var.schedule_config["scale_in_recurrence"]
  min_size               = var.schedule_config["scale_in_count"]
  desired_capacity       = var.schedule_config["scale_in_count"]
  max_size               = var.schedule_config["scale_in_count"]
}

resource "aws_autoscaling_schedule" "scale_out" {
  count                  = var.enable_schedule ? 1 : 0
  autoscaling_group_name = aws_autoscaling_group.gitlab_runner_instance.name
  scheduled_action_name  = "scale_out-${aws_autoscaling_group.gitlab_runner_instance.name}"
  recurrence             = var.schedule_config["scale_out_recurrence"]
  min_size               = var.schedule_config["scale_out_count"]
  desired_capacity       = var.schedule_config["scale_out_count"]
  max_size               = var.schedule_config["scale_out_count"]
}

data "aws_ami" "runner" {
  most_recent = "true"

  dynamic "filter" {
    for_each = var.ami_filter
    content {
      name   = filter.key
      values = filter.value
    }
  }

  owners = var.ami_owners
}

resource "aws_launch_configuration" "gitlab_runner_instance" {
  name_prefix          = var.runners_name
  security_groups      = [aws_security_group.runner.id]
  key_name             = var.ssh_key_pair
  image_id             = data.aws_ami.runner.id
  user_data            = local.template_user_data
  instance_type        = var.instance_type
  ebs_optimized        = var.runner_instance_ebs_optimized
  enable_monitoring    = var.runner_instance_enable_monitoring
  spot_price           = var.runner_instance_spot_price
  iam_instance_profile = aws_iam_instance_profile.instance.name
  dynamic "root_block_device" {
    for_each = [var.runner_root_block_device]
    content {
      delete_on_termination = lookup(root_block_device.value, "delete_on_termination", true)
      volume_type           = lookup(root_block_device.value, "volume_type", "gp2")
      volume_size           = lookup(root_block_device.value, "volume_size", 8)
      encrypted             = lookup(root_block_device.value, "encrypted", true)
      iops                  = lookup(root_block_device.value, "iops", null)
    }
  }

  associate_public_ip_address = false == var.runners_use_private_address

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
### Create config bucket & save config.toml there
################################################################################

module "config" {
  source = "./modules/config"

  name                          = var.environment
  runner_autoscaling_group_name = aws_autoscaling_group.gitlab_runner_instance.name
  gitlab_token_ssm_key          = local.secure_parameter_store_runner_token_key
  config_content                = local.runner_config
  tags                          = local.tags

  post_reload_script = var.post_reload_config
  config_bucket      = var.config_bucket
  config_key         = var.config_key
  cloudtrail_bucket  = var.cloudtrail_bucket
  cloudtrail_prefix  = var.cloudtrail_prefix
  extra_files_prefix = var.extra_files_prefix
  extra_files        = var.extra_files
}

resource "aws_iam_role_policy_attachment" "config_bucket" {
  role       = aws_iam_role.instance.name
  policy_arn = module.config.config_iam_policy_arn
}

################################################################################
### Create cache bucket
################################################################################
locals {
  bucket_name         = var.cache_bucket["create"] ? module.cache.bucket : lookup(var.cache_bucket, "bucket", "")
  cache_bucket_policy = var.cache_bucket["create"] ? module.cache.policy_arn : lookup(var.cache_bucket, "policy", "")
}

module "cache" {
  source = "./modules/cache"

  environment = var.environment
  tags        = local.tags

  create_cache_bucket                  = var.cache_bucket["create"]
  cache_bucket_prefix                  = var.cache_bucket_prefix
  cache_bucket_name_include_account_id = var.cache_bucket_name_include_account_id
  cache_bucket_set_random_suffix       = var.cache_bucket_set_random_suffix
  cache_bucket_versioning              = var.cache_bucket_versioning
  cache_expiration_days                = var.cache_expiration_days
}

################################################################################
### Trust policy
################################################################################
resource "aws_iam_instance_profile" "instance" {
  name = "${var.environment}-instance-profile"
  role = aws_iam_role.instance.name
}

resource "aws_iam_role" "instance" {
  name                 = "${var.environment}-instance-role"
  assume_role_policy   = length(var.instance_role_json) > 0 ? var.instance_role_json : templatefile("${path.module}/policies/instance-role-trust-policy.json", {})
  permissions_boundary = var.permissions_boundary == "" ? null : "${var.arn_format}:iam::${data.aws_caller_identity.current.account_id}:policy/${var.permissions_boundary}"
}

################################################################################
### Policies for runner agent instance to create docker machines via spot req.
################################################################################
resource "aws_iam_policy" "instance_docker_machine_policy" {
  name        = "${var.environment}-docker-machine"
  path        = "/"
  description = "Policy for docker machine."

  policy = templatefile("${path.module}/policies/instance-docker-machine-policy.json", {})
}

resource "aws_iam_role_policy_attachment" "instance_docker_machine_policy" {
  role       = aws_iam_role.instance.name
  policy_arn = aws_iam_policy.instance_docker_machine_policy.arn
}

################################################################################
### Policies for runner agent instance to allow connection via Session Manager
################################################################################
resource "aws_iam_policy" "instance_session_manager_policy" {
  count = var.enable_runner_ssm_access ? 1 : 0

  name        = "${var.environment}-session-manager"
  path        = "/"
  description = "Policy session manager."

  policy = templatefile("${path.module}/policies/instance-session-manager-policy.json", {})
}

resource "aws_iam_role_policy_attachment" "instance_session_manager_policy" {
  count = var.enable_runner_ssm_access ? 1 : 0

  role       = aws_iam_role.instance.name
  policy_arn = aws_iam_policy.instance_session_manager_policy[0].arn
}

resource "aws_iam_role_policy_attachment" "instance_session_manager_aws_managed" {
  count = var.enable_runner_ssm_access ? 1 : 0

  role       = aws_iam_role.instance.name
  policy_arn = "${var.arn_format}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

################################################################################
### Add user defined policies
################################################################################
resource "aws_iam_role_policy_attachment" "user_defined_policies" {
  count      = length(var.runner_iam_policy_arns)
  role       = aws_iam_role.instance.name
  policy_arn = var.runner_iam_policy_arns[count.index]
}

################################################################################
### Policy for the docker machine instance to access cache
################################################################################
resource "aws_iam_role_policy_attachment" "docker_machine_cache_instance" {
  count      = var.cache_bucket["create"] || lookup(var.cache_bucket, "policy", "") != "" ? 1 : 0
  role       = aws_iam_role.instance.name
  policy_arn = local.cache_bucket_policy
}

################################################################################
### docker machine instance policy
################################################################################
resource "aws_iam_role" "docker_machine" {
  name                 = "${var.environment}-docker-machine-role"
  assume_role_policy   = length(var.docker_machine_role_json) > 0 ? var.docker_machine_role_json : templatefile("${path.module}/policies/instance-role-trust-policy.json", {})
  permissions_boundary = var.permissions_boundary == "" ? null : "${var.arn_format}:iam::${data.aws_caller_identity.current.account_id}:policy/${var.permissions_boundary}"
}

resource "aws_iam_instance_profile" "docker_machine" {
  name = "${var.environment}-docker-machine-profile"
  role = aws_iam_role.docker_machine.name
}

################################################################################
### Add user defined policies
################################################################################
resource "aws_iam_role_policy_attachment" "docker_machine_user_defined_policies" {
  count      = length(var.docker_machine_iam_policy_arns)
  role       = aws_iam_role.docker_machine.name
  policy_arn = var.docker_machine_iam_policy_arns[count.index]
}

################################################################################
resource "aws_iam_role_policy_attachment" "docker_machine_session_manager_aws_managed" {
  count = var.enable_docker_machine_ssm_access ? 1 : 0

  role       = aws_iam_role.docker_machine.name
  policy_arn = "${var.arn_format}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

################################################################################
### Service linked policy, optional
################################################################################
resource "aws_iam_policy" "service_linked_role" {
  count = var.allow_iam_service_linked_role_creation ? 1 : 0

  name        = "${var.environment}-service_linked_role"
  path        = "/"
  description = "Policy for creation of service linked roles."

  policy = templatefile("${path.module}/policies/service-linked-role-create-policy.json", {
    arn_format = var.arn_format
  })
}

resource "aws_iam_role_policy_attachment" "service_linked_role" {
  count = var.allow_iam_service_linked_role_creation ? 1 : 0

  role       = aws_iam_role.instance.name
  policy_arn = aws_iam_policy.service_linked_role[0].arn
}

resource "aws_eip" "gitlab_runner" {
  count = var.enable_eip ? 1 : 0
}

################################################################################
### AWS Systems Manager access to store runner token once registered
################################################################################
resource "aws_iam_policy" "ssm" {
  count = var.enable_manage_gitlab_token ? 1 : 0

  name        = "${var.environment}-ssm"
  path        = "/"
  description = "Policy for runner token param access via SSM"

  policy = templatefile("${path.module}/policies/instance-secure-parameter-role-policy.json", {
    arn_format = var.arn_format
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  count = var.enable_manage_gitlab_token ? 1 : 0

  role       = aws_iam_role.instance.name
  policy_arn = aws_iam_policy.ssm[0].arn
}

################################################################################
### AWS assign EIP
################################################################################
resource "aws_iam_policy" "eip" {
  count = var.enable_eip ? 1 : 0

  name        = "${var.environment}-eip"
  path        = "/"
  description = "Policy for runner to assign EIP"

  policy = templatefile("${path.module}/policies/instance-eip.json", {})
}

resource "aws_iam_role_policy_attachment" "eip" {
  count = var.enable_eip ? 1 : 0

  role       = aws_iam_role.instance.name
  policy_arn = aws_iam_policy.eip[0].arn
}

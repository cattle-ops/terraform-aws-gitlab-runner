data "aws_caller_identity" "current" {}

data "aws_subnet" "runners" {
  id = length(var.subnet_id) > 0 ? var.subnet_id : var.subnet_id_runners
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

resource "aws_ssm_parameter" "runner_sentry_dsn" {
  name  = local.secure_parameter_store_runner_sentry_dsn
  type  = "SecureString"
  value = "null"

  tags = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

locals {
  template_user_data = templatefile("${path.module}/template/user-data.tpl",
    {
      eip                 = var.enable_eip ? local.template_eip : ""
      logging             = var.enable_cloudwatch_logging ? local.logging_user_data : ""
      gitlab_runner       = local.template_gitlab_runner
      user_data_trace_log = var.enable_runner_user_data_trace_log
  })

  template_eip = templatefile("${path.module}/template/eip.tpl", {
    eip = join(",", aws_eip.gitlab_runner.*.public_ip)
  })

  template_gitlab_runner = templatefile("${path.module}/template/gitlab-runner.tpl",
    {
      gitlab_runner_version                        = var.gitlab_runner_version
      docker_machine_version                       = var.docker_machine_version
      docker_machine_download_url                  = var.docker_machine_download_url
      runners_config                               = local.template_runner_config
      runners_executor                             = var.runners_executor
      runners_install_amazon_ecr_credential_helper = var.runners_install_amazon_ecr_credential_helper
      pre_install                                  = var.userdata_pre_install
      post_install                                 = var.userdata_post_install
      runners_gitlab_url                           = var.runners_gitlab_url
      runners_token                                = var.runners_token
      secure_parameter_store_runner_token_key      = local.secure_parameter_store_runner_token_key
      secure_parameter_store_runner_sentry_dsn     = local.secure_parameter_store_runner_sentry_dsn
      secure_parameter_store_region                = var.aws_region
      gitlab_runner_registration_token             = var.gitlab_runner_registration_config["registration_token"]
      giltab_runner_description                    = var.gitlab_runner_registration_config["description"]
      gitlab_runner_tag_list                       = var.gitlab_runner_registration_config["tag_list"]
      gitlab_runner_locked_to_project              = var.gitlab_runner_registration_config["locked_to_project"]
      gitlab_runner_run_untagged                   = var.gitlab_runner_registration_config["run_untagged"]
      gitlab_runner_maximum_timeout                = var.gitlab_runner_registration_config["maximum_timeout"]
      gitlab_runner_access_level                   = lookup(var.gitlab_runner_registration_config, "access_level", "not_protected")
      sentry_dsn                                   = var.sentry_dsn
  })

  template_runner_config = templatefile("${path.module}/template/runner-config.tpl",
    {
      aws_region                  = var.aws_region
      gitlab_url                  = var.runners_gitlab_url
      runners_vpc_id              = var.vpc_id
      runners_subnet_id           = length(var.subnet_id) > 0 ? var.subnet_id : var.subnet_id_runners
      runners_aws_zone            = data.aws_availability_zone.runners.name_suffix
      runners_instance_type       = var.docker_machine_instance_type
      runners_spot_price_bid      = var.docker_machine_spot_price_bid == "on-demand-price" ? "" : var.docker_machine_spot_price_bid
      runners_ami                 = data.aws_ami.docker-machine.id
      runners_security_group_name = aws_security_group.docker_machine.name
      runners_monitoring          = var.runners_monitoring
      runners_ebs_optimized       = var.runners_ebs_optimized
      runners_instance_profile    = aws_iam_instance_profile.docker_machine.name
      runners_additional_volumes  = local.runners_additional_volumes
      docker_machine_options      = length(local.docker_machine_options_string) == 1 ? "" : local.docker_machine_options_string
      runners_name                = var.runners_name
      runners_tags = replace(replace(var.overrides["name_docker_machine_runners"] == "" ? format(
        "Name,%s-docker-machine,%s,%s",
        var.environment,
        local.tags_string,
        local.runner_tags_string,
        ) : format(
        "%s,%s,Name,%s",
        local.tags_string,
        local.runner_tags_string,
        var.overrides["name_docker_machine_runners"],
      ), ",,", ","), "/,$/", "")
      runners_token                     = var.runners_token
      runners_executor                  = var.runners_executor
      runners_limit                     = var.runners_limit
      runners_concurrent                = var.runners_concurrent
      runners_image                     = var.runners_image
      runners_privileged                = var.runners_privileged
      runners_disable_cache             = var.runners_disable_cache
      runners_docker_runtime            = var.runners_docker_runtime
      runners_helper_image              = var.runners_helper_image
      runners_shm_size                  = var.runners_shm_size
      runners_pull_policy               = var.runners_pull_policy
      runners_idle_count                = var.runners_idle_count
      runners_idle_time                 = var.runners_idle_time
      runners_max_builds                = local.runners_max_builds_string
      runners_machine_autoscaling       = local.runners_machine_autoscaling
      runners_root_size                 = var.runners_root_size
      runners_iam_instance_profile_name = var.runners_iam_instance_profile_name
      runners_use_private_address_only  = var.runners_use_private_address
      runners_use_private_address       = !var.runners_use_private_address
      runners_request_spot_instance     = var.runners_request_spot_instance
      runners_environment_vars          = jsonencode(var.runners_environment_vars)
      runners_pre_build_script          = var.runners_pre_build_script
      runners_post_build_script         = var.runners_post_build_script
      runners_pre_clone_script          = var.runners_pre_clone_script
      runners_request_concurrency       = var.runners_request_concurrency
      runners_output_limit              = var.runners_output_limit
      runners_check_interval            = var.runners_check_interval
      runners_volumes_tmpfs             = join(",", [for v in var.runners_volumes_tmpfs : format("\"%s\" = \"%s\"", v.volume, v.options)])
      runners_services_volumes_tmpfs    = join(",", [for v in var.runners_services_volumes_tmpfs : format("\"%s\" = \"%s\"", v.volume, v.options)])
      bucket_name                       = local.bucket_name
      shared_cache                      = var.cache_shared
      sentry_dsn                        = var.sentry_dsn
    }
  )
}

data "aws_ami" "docker-machine" {
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
  name                      = var.enable_asg_recreation ? "${aws_launch_template.gitlab_runner_instance.name}-asg" : "${var.environment}-as-group"
  vpc_zone_identifier       = length(var.subnet_id) > 0 ? [var.subnet_id] : var.subnet_ids_gitlab_runner
  min_size                  = "1"
  max_size                  = "1"
  desired_capacity          = "1"
  health_check_grace_period = 0
  max_instance_lifetime     = var.asg_max_instance_lifetime
  enabled_metrics           = var.metrics_autoscaling
  tags                      = local.agent_tags_propagated

  launch_template {
    id      = aws_launch_template.gitlab_runner_instance.id
    version = aws_launch_template.gitlab_runner_instance.latest_version
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 0
    }
    triggers = ["tag"]
  }

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

resource "aws_launch_template" "gitlab_runner_instance" {
  name_prefix            = local.name_runner_agent_instance
  image_id               = data.aws_ami.runner.id
  user_data              = base64encode(local.template_user_data)
  instance_type          = var.instance_type
  update_default_version = true
  ebs_optimized          = var.runner_instance_ebs_optimized
  monitoring {
    enabled = var.runner_instance_enable_monitoring
  }
  dynamic "instance_market_options" {
    for_each = var.runner_instance_spot_price == null || var.runner_instance_spot_price == "" ? [] : ["spot"]
    content {
      market_type = instance_market_options.value
      spot_options {
        max_price = var.runner_instance_spot_price == "on-demand-price" ? "" : var.runner_instance_spot_price
      }
    }
  }
  iam_instance_profile {
    name = aws_iam_instance_profile.instance.name
  }
  dynamic "block_device_mappings" {
    for_each = [var.runner_root_block_device]
    content {
      device_name = lookup(block_device_mappings.value, "device_name", "/dev/xvda")
      ebs {
        delete_on_termination = lookup(block_device_mappings.value, "delete_on_termination", true)
        volume_type           = lookup(block_device_mappings.value, "volume_type", "gp3")
        volume_size           = lookup(block_device_mappings.value, "volume_size", 8)
        encrypted             = lookup(block_device_mappings.value, "encrypted", true)
        iops                  = lookup(block_device_mappings.value, "iops", null)
        throughput            = lookup(block_device_mappings.value, "throughput", null)
        kms_key_id            = lookup(block_device_mappings.value, "kms_key_id", null)
      }
    }
  }
  network_interfaces {
    security_groups             = concat([aws_security_group.runner.id], var.extra_security_group_ids_runner_agent)
    associate_public_ip_address = false == (var.runner_agent_uses_private_address == false ? var.runner_agent_uses_private_address : var.runners_use_private_address)
  }
  tag_specifications {
    resource_type = "instance"
    tags          = local.tags
  }
  tag_specifications {
    resource_type = "volume"
    tags          = local.tags
  }
  dynamic "tag_specifications" {
    for_each = var.runner_instance_spot_price == null || var.runner_instance_spot_price == "" ? [] : ["spot"]
    content {
      resource_type = "spot-instances-request"
      tags          = local.tags
    }
  }

  tags = local.tags

  metadata_options {
    http_endpoint = var.runner_instance_metadata_options_http_endpoint
    http_tokens   = var.runner_instance_metadata_options_http_tokens
  }

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
### Create cache bucket
################################################################################
locals {
  bucket_name   = var.cache_bucket["create"] ? module.cache.bucket : lookup(var.cache_bucket, "bucket", "")
  bucket_policy = var.cache_bucket["create"] ? module.cache.policy_arn : lookup(var.cache_bucket, "policy", "")
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

  name_iam_objects = local.name_iam_objects
}

################################################################################
### Trust policy
################################################################################
resource "aws_iam_instance_profile" "instance" {
  name = "${local.name_iam_objects}-instance"
  role = aws_iam_role.instance.name
  tags = local.tags
}

resource "aws_iam_role" "instance" {
  name                 = "${local.name_iam_objects}-instance"
  assume_role_policy   = length(var.instance_role_json) > 0 ? var.instance_role_json : templatefile("${path.module}/policies/instance-role-trust-policy.json", {})
  permissions_boundary = var.permissions_boundary == "" ? null : "${var.arn_format}:iam::${data.aws_caller_identity.current.account_id}:policy/${var.permissions_boundary}"
  tags                 = merge(local.tags, var.role_tags)
}

################################################################################
### Policies for runner agent instance to create docker machines via spot req.
###
### iam:PassRole To pass the role from the agent to the docker machine runners
################################################################################
resource "aws_iam_policy" "instance_docker_machine_policy" {
  name        = "${local.name_iam_objects}-docker-machine"
  path        = "/"
  description = "Policy for docker machine."
  policy = templatefile("${path.module}/policies/instance-docker-machine-policy.json",
    {
      docker_machine_role_arn = aws_iam_role.docker_machine.arn
  })
  tags = local.tags
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

  name        = "${local.name_iam_objects}-session-manager"
  path        = "/"
  description = "Policy session manager."
  policy      = templatefile("${path.module}/policies/instance-session-manager-policy.json", {})
  tags        = local.tags
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
  policy_arn = local.bucket_policy
}

################################################################################
### docker machine instance policy
################################################################################
resource "aws_iam_role" "docker_machine" {
  name                 = "${local.name_iam_objects}-docker-machine"
  assume_role_policy   = length(var.docker_machine_role_json) > 0 ? var.docker_machine_role_json : templatefile("${path.module}/policies/instance-role-trust-policy.json", {})
  permissions_boundary = var.permissions_boundary == "" ? null : "${var.arn_format}:iam::${data.aws_caller_identity.current.account_id}:policy/${var.permissions_boundary}"
  tags                 = local.tags
}

resource "aws_iam_instance_profile" "docker_machine" {
  name = "${local.name_iam_objects}-docker-machine"
  role = aws_iam_role.docker_machine.name
  tags = local.tags
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

  name        = "${local.name_iam_objects}-service_linked_role"
  path        = "/"
  description = "Policy for creation of service linked roles."
  policy      = templatefile("${path.module}/policies/service-linked-role-create-policy.json", { arn_format = var.arn_format })
  tags        = local.tags
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

  name        = "${local.name_iam_objects}-ssm"
  path        = "/"
  description = "Policy for runner token param access via SSM"
  policy      = templatefile("${path.module}/policies/instance-secure-parameter-role-policy.json", { arn_format = var.arn_format })
  tags        = local.tags
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

  name        = "${local.name_iam_objects}-eip"
  path        = "/"
  description = "Policy for runner to assign EIP"
  policy      = templatefile("${path.module}/policies/instance-eip.json", {})
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "eip" {
  count = var.enable_eip ? 1 : 0

  role       = aws_iam_role.instance.name
  policy_arn = aws_iam_policy.eip[0].arn
}

################################################################################
### Lambda function for ASG instance termination lifecycle hook
################################################################################
module "terminate_instances_lifecycle_function" {
  source = "./modules/terminate-instances"

  count = var.asg_terminate_lifecycle_hook_create ? 1 : 0

  name                                 = var.asg_terminate_lifecycle_hook_name == null ? "terminate-instances" : var.asg_terminate_lifecycle_hook_name
  environment                          = var.environment
  asg_arn                              = aws_autoscaling_group.gitlab_runner_instance.arn
  asg_name                             = aws_autoscaling_group.gitlab_runner_instance.name
  cloudwatch_logging_retention_in_days = var.cloudwatch_logging_retention_in_days
  lambda_memory_size                   = var.asg_terminate_lifecycle_lambda_memory_size
  lifecycle_heartbeat_timeout          = var.asg_terminate_lifecycle_hook_heartbeat_timeout
  name_iam_objects                     = local.name_iam_objects
  role_permissions_boundary            = var.permissions_boundary == "" ? null : "${var.arn_format}:iam::${data.aws_caller_identity.current.account_id}:policy/${var.permissions_boundary}"
  lambda_timeout                       = var.asg_terminate_lifecycle_lambda_timeout
  tags                                 = local.tags
}
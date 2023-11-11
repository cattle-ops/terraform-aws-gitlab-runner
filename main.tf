# Parameter value is managed by the user-data script of the gitlab runner instance
resource "aws_ssm_parameter" "runner_registration_token" {
  name  = local.secure_parameter_store_runner_token_key
  type  = "SecureString"
  value = "null"

  key_id = local.kms_key

  tags = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "runner_sentry_dsn" {
  name  = local.secure_parameter_store_runner_sentry_dsn
  type  = "SecureString"
  value = "null"

  key_id = local.kms_key

  tags = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

locals {
  template_user_data = templatefile("${path.module}/template/user-data.tftpl",
    {
      eip                 = var.runner_instance.use_eip ? local.template_eip : ""
      logging             = var.runner_cloudwatch.enable ? local.logging_user_data : ""
      gitlab_runner       = local.template_gitlab_runner
      user_data_trace_log = var.debug.trace_runner_user_data
      yum_update          = var.runner_install.yum_update ? local.file_yum_update : ""
      extra_config        = var.runner_install.start_script
  })

  file_yum_update = file("${path.module}/template/yum_update.tftpl")

  template_eip = templatefile("${path.module}/template/eip.tftpl", {
    eip = join(",", [for eip in aws_eip.gitlab_runner : eip.public_ip])
  })

  template_gitlab_runner = templatefile("${path.module}/template/gitlab-runner.tftpl",
    {
      gitlab_runner_version                                        = var.runner_gitlab.runner_version
      docker_machine_version                                       = var.runner_install.docker_machine_version
      docker_machine_download_url                                  = var.runner_install.docker_machine_download_url
      runners_config                                               = local.template_runner_config
      runners_userdata                                             = var.runner_worker_docker_machine_instance.start_script
      runners_executor                                             = var.runner_worker.type
      runners_install_amazon_ecr_credential_helper                 = var.runner_install.amazon_ecr_credential_helper
      curl_cacert                                                  = length(var.runner_gitlab.certificate) > 0 ? "--cacert /etc/gitlab-runner/certs/gitlab.crt" : ""
      pre_install_certificates                                     = local.pre_install_certificates
      pre_install                                                  = var.runner_install.pre_install_script
      post_install                                                 = var.runner_install.post_install_script
      runners_gitlab_url                                           = var.runner_gitlab.url
      runners_token                                                = var.runner_gitlab.registration_token
      secure_parameter_store_gitlab_runner_registration_token_name = var.runner_gitlab_registration_token_secure_parameter_store_name
      secure_parameter_store_runner_token_key                      = local.secure_parameter_store_runner_token_key
      secure_parameter_store_runner_sentry_dsn                     = local.secure_parameter_store_runner_sentry_dsn
      secure_parameter_store_gitlab_token_name                     = var.runner_gitlab.access_token_secure_parameter_store_name
      secure_parameter_store_region                                = data.aws_region.current.name
      gitlab_runner_registration_token                             = var.runner_gitlab_registration_config.registration_token
      gitlab_runner_description                                    = var.runner_gitlab_registration_config["description"]
      gitlab_runner_tag_list                                       = var.runner_gitlab_registration_config["tag_list"]
      gitlab_runner_locked_to_project                              = var.runner_gitlab_registration_config["locked_to_project"]
      gitlab_runner_run_untagged                                   = var.runner_gitlab_registration_config["run_untagged"]
      gitlab_runner_maximum_timeout                                = var.runner_gitlab_registration_config["maximum_timeout"]
      gitlab_runner_type                                           = var.runner_gitlab_registration_config["type"]
      gitlab_runner_group_id                                       = var.runner_gitlab_registration_config["group_id"]
      gitlab_runner_project_id                                     = var.runner_gitlab_registration_config["project_id"]
      gitlab_runner_access_level                                   = var.runner_gitlab_registration_config.access_level
      sentry_dsn                                                   = var.runner_manager.sentry_dsn
      public_key                                                   = var.runner_worker_docker_machine_fleet.enable == true ? tls_private_key.fleet[0].public_key_openssh : ""
      use_fleet                                                    = var.runner_worker_docker_machine_fleet.enable
      private_key                                                  = var.runner_worker_docker_machine_fleet.enable == true ? tls_private_key.fleet[0].private_key_pem : ""
      use_new_runner_authentication_gitlab_16                      = var.runner_gitlab_registration_config.type != ""
  })

  template_runner_config = templatefile("${path.module}/template/runner-config.tftpl",
    {
      aws_region       = data.aws_region.current.name
      gitlab_url       = var.runner_gitlab.url
      gitlab_clone_url = var.runner_gitlab.url_clone
      tls_ca_file      = length(var.runner_gitlab.certificate) > 0 ? "tls-ca-file=\"/etc/gitlab-runner/certs/gitlab.crt\"" : ""
      runners_machine_autoscaling = [for config in var.runner_worker_docker_machine_autoscaling_options : {
        for key, value in config :
        # Convert key from snake_case to PascalCase which is the casing for this section.
        join("", [for subkey in split("_", key) : title(subkey)]) => jsonencode(value) if value != null
      }]
      runners_vpc_id                    = var.vpc_id
      runners_subnet_id                 = var.subnet_id
      runners_subnet_ids                = length(var.runner_worker_docker_machine_instance.subnet_ids) > 0 ? var.runner_worker_docker_machine_instance.subnet_ids : [var.subnet_id]
      runners_aws_zone                  = data.aws_availability_zone.runners.name_suffix
      runners_instance_types            = var.runner_worker_docker_machine_instance.types
      runners_spot_price_bid            = var.runner_worker_docker_machine_instance_spot.max_price == "on-demand-price" || var.runner_worker_docker_machine_instance_spot.max_price == null ? "" : var.runner_worker_docker_machine_instance_spot.max_price
      runners_ami                       = var.runner_worker.type == "docker+machine" ? data.aws_ami.docker-machine[0].id : ""
      runners_security_group_name       = var.runner_worker.type == "docker+machine" ? aws_security_group.docker_machine[0].name : ""
      runners_max_growth_rate           = var.runner_worker_docker_machine_instance.max_growth_rate
      runners_monitoring                = var.runner_worker_docker_machine_instance.monitoring
      runners_ebs_optimized             = var.runner_worker_docker_machine_instance.ebs_optimized
      runners_instance_profile          = var.runner_worker.type == "docker+machine" ? aws_iam_instance_profile.docker_machine[0].name : ""
      docker_machine_options            = length(local.docker_machine_options_string) == 1 ? "" : local.docker_machine_options_string
      docker_machine_name               = format("%s-%s", local.runner_tags_merged["Name"], "%s") # %s is always needed
      runners_name                      = var.runner_instance.name
      runners_tags                      = replace(replace(local.runner_tags_string, ",,", ","), "/,$/", "")
      runners_token                     = var.runner_gitlab.registration_token
      runners_userdata                  = var.runner_worker_docker_machine_instance.start_script
      runners_executor                  = var.runner_worker.type
      runners_limit                     = var.runner_worker.max_jobs
      runners_concurrent                = var.runner_manager.maximum_concurrent_jobs
      runners_pull_policies             = local.runners_pull_policies
      runners_idle_count                = var.runner_worker_docker_machine_instance.idle_count
      runners_idle_time                 = var.runner_worker_docker_machine_instance.idle_time
      runners_max_builds                = local.runners_max_builds_string
      runners_root_size                 = var.runner_worker_docker_machine_instance.root_size
      runners_volume_type               = var.runner_worker_docker_machine_instance.volume_type
      runners_iam_instance_profile_name = var.runner_worker_docker_machine_role.profile_name
      runners_use_private_address_only  = var.runner_worker_docker_machine_instance.private_address_only
      runners_use_private_address       = !var.runner_worker_docker_machine_instance.private_address_only
      runners_request_spot_instance     = var.runner_worker_docker_machine_instance_spot.enable
      runners_environment_vars          = jsonencode(var.runner_worker.environment_variables)
      runners_pre_build_script          = var.runner_worker_gitlab_pipeline.pre_build_script
      runners_post_build_script         = var.runner_worker_gitlab_pipeline.post_build_script
      runners_pre_clone_script          = var.runner_worker_gitlab_pipeline.pre_clone_script
      runners_request_concurrency       = var.runner_worker.request_concurrency
      runners_output_limit              = var.runner_worker.output_limit
      runners_check_interval            = var.runner_manager.gitlab_check_interval
      runners_volumes_tmpfs             = join("\n", [for v in var.runner_worker_docker_volumes_tmpfs : format("\"%s\" = \"%s\"", v.volume, v.options)])
      runners_services_volumes_tmpfs    = join("\n", [for v in var.runner_worker_docker_services_volumes_tmpfs : format("\"%s\" = \"%s\"", v.volume, v.options)])
      runners_docker_services           = local.runners_docker_services
      runners_docker_options            = local.runners_docker_options_toml
      bucket_name                       = local.bucket_name
      shared_cache                      = var.runner_worker_cache.shared
      sentry_dsn                        = var.runner_manager.sentry_dsn
      prometheus_listen_address         = var.runner_manager.prometheus_listen_address
      auth_type                         = var.runner_worker_cache.authentication_type
      use_fleet                         = var.runner_worker_docker_machine_fleet.enable
      launch_template                   = var.runner_worker_docker_machine_fleet.enable == true ? aws_launch_template.fleet_gitlab_runner[0].name : ""
    }
  )
}

# ignores: Autoscaling Groups Supply Tags --> we use a "dynamic" block to create the tags
# ignores: Auto Scaling Group With No Associated ELB --> that's simply not true, as the EC2 instance contacts GitLab. So no ELB needed here.
# kics-scan ignore-line
resource "aws_autoscaling_group" "gitlab_runner_instance" {
  # TODO Please explain how `agent_enable_asg_recreation` works
  name                      = var.runner_enable_asg_recreation ? "${aws_launch_template.gitlab_runner_instance.name}-asg" : "${var.environment}-as-group"
  vpc_zone_identifier       = length(var.runner_worker_docker_machine_instance.subnet_ids) > 0 ? var.runner_worker_docker_machine_instance.subnet_ids : [var.subnet_id]
  min_size                  = "1"
  max_size                  = "1"
  desired_capacity          = "1"
  health_check_grace_period = 0
  max_instance_lifetime     = var.runner_instance.max_lifetime_seconds
  enabled_metrics           = var.runner_instance.collect_autoscaling_metrics

  dynamic "tag" {
    for_each = local.agent_tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

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
    delete = var.runner_terraform_timeout_delete_asg
  }
  lifecycle {
    ignore_changes = [min_size, max_size, desired_capacity]
  }
}

resource "aws_autoscaling_schedule" "scale_in" {
  count                  = var.runner_schedule_enable ? 1 : 0
  autoscaling_group_name = aws_autoscaling_group.gitlab_runner_instance.name
  scheduled_action_name  = "scale_in-${aws_autoscaling_group.gitlab_runner_instance.name}"
  recurrence             = var.runner_schedule_config["scale_in_recurrence"]
  time_zone              = try(var.runner_schedule_config["scale_in_time_zone"], "Etc/UTC")
  min_size               = try(var.runner_schedule_config["scale_in_min_size"], var.runner_schedule_config["scale_in_count"])
  desired_capacity       = try(var.runner_schedule_config["scale_in_desired_capacity"], var.runner_schedule_config["scale_in_count"])
  max_size               = try(var.runner_schedule_config["scale_in_max_size"], var.runner_schedule_config["scale_in_count"])
}

resource "aws_autoscaling_schedule" "scale_out" {
  count                  = var.runner_schedule_enable ? 1 : 0
  autoscaling_group_name = aws_autoscaling_group.gitlab_runner_instance.name
  scheduled_action_name  = "scale_out-${aws_autoscaling_group.gitlab_runner_instance.name}"
  recurrence             = var.runner_schedule_config["scale_out_recurrence"]
  time_zone              = try(var.runner_schedule_config["scale_out_time_zone"], "Etc/UTC")
  min_size               = try(var.runner_schedule_config["scale_out_min_size"], var.runner_schedule_config["scale_out_count"])
  desired_capacity       = try(var.runner_schedule_config["scale_out_desired_capacity"], var.runner_schedule_config["scale_out_count"])
  max_size               = try(var.runner_schedule_config["scale_out_max_size"], var.runner_schedule_config["scale_out_count"])
}

resource "aws_launch_template" "gitlab_runner_instance" {
  # checkov:skip=CKV_AWS_341:Hop limit > 1 needed here in case of Docker builds. Otherwise the token is invalid within Docker.
  # checkov:skip=CKV_AWS_88:User can decide to add a public IP.
  # checkov:skip=CKV_AWS_79:User can decide to enable Metadata service V2. V2 is the default.
  name_prefix = "${local.name_runner_agent_instance}-"

  image_id               = data.aws_ami.runner.id
  user_data              = base64gzip(local.template_user_data)
  instance_type          = var.runner_instance.type
  update_default_version = true
  ebs_optimized          = var.runner_instance.ebs_optimized
  monitoring {
    enabled = var.runner_instance.monitoring
  }
  dynamic "instance_market_options" {
    for_each = var.runner_instance.spot_price == null || var.runner_instance.spot_price == "" ? [] : ["spot"]
    content {
      market_type = instance_market_options.value
      dynamic "spot_options" {
        for_each = var.runner_instance.spot_price == "on-demand-price" ? [] : [0]
        content {
          max_price = var.runner_instance.spot_price
        }
      }
    }
  }
  iam_instance_profile {
    name = local.aws_iam_role_instance_name
  }
  dynamic "block_device_mappings" {
    for_each = [var.runner_instance.root_device_config]
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
    security_groups             = concat([aws_security_group.runner.id], var.runner_networking.security_group_ids)
    associate_public_ip_address = false == (var.runner_instance.private_address_only == false ? var.runner_instance.private_address_only : var.runner_worker_docker_machine_instance.private_address_only)
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
    for_each = var.runner_instance.spot_price == null || var.runner_instance.spot_price == "" ? [] : ["spot"]
    content {
      resource_type = "spot-instances-request"
      tags          = local.tags
    }
  }

  tags = local.tags

  metadata_options {
    http_endpoint               = var.runner_metadata_options.http_endpoint
    http_tokens                 = var.runner_metadata_options.http_tokens
    http_put_response_hop_limit = var.runner_metadata_options.http_put_response_hop_limit
    instance_metadata_tags      = var.runner_metadata_options.instance_metadata_tags
  }

  lifecycle {
    create_before_destroy = true
  }

  # otherwise the agent running on the EC2 instance tries to create the log group
  depends_on = [aws_cloudwatch_log_group.environment]
}

resource "tls_private_key" "fleet" {
  count = var.runner_worker_docker_machine_fleet.enable == true && var.runner_worker.type == "docker+machine" ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "fleet" {
  count = var.runner_worker_docker_machine_fleet.enable == true && var.runner_worker.type == "docker+machine" ? 1 : 0

  key_name   = "${var.environment}-${var.runner_worker_docker_machine_fleet.key_pair_name}"
  public_key = tls_private_key.fleet[0].public_key_openssh

  tags = local.tags
}

resource "aws_launch_template" "fleet_gitlab_runner" {
  # checkov:skip=CKV_AWS_88:User can decide to add a public IP.
  # checkov:skip=CKV_AWS_79:User can decide to enable Metadata service V2. V2 is the default.
  count       = var.runner_worker_docker_machine_fleet.enable == true && var.runner_worker.type == "docker+machine" ? 1 : 0
  name_prefix = "${local.name_runner_agent_instance}-worker-"

  key_name               = aws_key_pair.fleet[0].key_name
  image_id               = data.aws_ami.docker-machine[0].id
  user_data              = base64gzip(var.runner_worker_docker_machine_instance.start_script)
  instance_type          = var.runner_worker_docker_machine_instance.types[0] # it will be override by the fleet
  update_default_version = true
  ebs_optimized          = var.runner_worker_docker_machine_instance.ebs_optimized
  monitoring {
    enabled = var.runner_worker_docker_machine_instance.monitoring
  }
  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = var.runner_worker_docker_machine_instance.root_size
      volume_type = var.runner_worker_docker_machine_instance.volume_type
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.docker_machine[0].name
  }

  network_interfaces {
    security_groups             = [aws_security_group.docker_machine[0].id]
    associate_public_ip_address = !var.runner_worker_docker_machine_instance.private_address_only
  }

  tag_specifications {
    resource_type = "instance"
    tags          = local.tags
  }
  tag_specifications {
    resource_type = "volume"
    tags          = local.tags
  }

  tags = local.tags

  metadata_options {
    http_tokens                 = var.runner_worker_docker_machine_ec2_metadata_options.http_tokens
    http_put_response_hop_limit = var.runner_worker_docker_machine_ec2_metadata_options.http_put_response_hop_limit
    instance_metadata_tags      = "enabled"
  }

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
### Create cache bucket
################################################################################
locals {
  bucket_name   = var.runner_worker_cache["create"] ? module.cache[0].bucket : var.runner_worker_cache["bucket"]
  bucket_policy = var.runner_worker_cache["create"] ? module.cache[0].policy_arn : var.runner_worker_cache["policy"]
}

module "cache" {
  count  = var.runner_worker_cache["create"] ? 1 : 0
  source = "./modules/cache"

  environment = var.environment
  tags        = local.tags

  cache_bucket_prefix                  = var.runner_worker_cache.bucket_prefix
  cache_bucket_name_include_account_id = var.runner_worker_cache.include_account_id
  cache_bucket_set_random_suffix       = var.runner_worker_cache.random_suffix
  cache_bucket_versioning              = var.runner_worker_cache.versioning
  cache_expiration_days                = var.runner_worker_cache.expiration_days
  cache_lifecycle_prefix               = var.runner_worker_cache.shared ? "project/" : "runner/"
  cache_logging_bucket                 = var.runner_worker_cache.access_log_bucket_id
  cache_logging_bucket_prefix          = var.runner_worker_cache.access_log_bucket_prefix

  kms_key_id = local.kms_key

  name_iam_objects = local.name_iam_objects
}

################################################################################
### Trust policy
################################################################################
resource "aws_iam_instance_profile" "instance" {
  count = var.runner_role.create_role_profile ? 1 : 0

  name = local.aws_iam_role_instance_name
  role = local.aws_iam_role_instance_name

  tags = local.tags
}

resource "aws_iam_role" "instance" {
  count = var.runner_role.create_role_profile ? 1 : 0

  name                 = local.aws_iam_role_instance_name
  assume_role_policy   = length(var.runner_role.assume_role_policy_json) > 0 ? var.runner_role.assume_role_policy_json : templatefile("${path.module}/policies/instance-role-trust-policy.json", {})
  permissions_boundary = var.iam_permissions_boundary == "" ? null : "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:policy/${var.iam_permissions_boundary}"

  tags = merge(local.tags, var.runner_role.additional_tags)
}

################################################################################
### Policy for the instance to use the KMS key
################################################################################
resource "aws_iam_policy" "instance_kms_policy" {
  count = var.enable_managed_kms_key ? 1 : 0

  name        = "${local.name_iam_objects}-kms"
  path        = "/"
  description = "Allow runner instance the ability to use the KMS key."
  policy = templatefile("${path.module}/policies/instance-kms-policy.json",
    {
      kms_key_arn = var.enable_managed_kms_key && var.kms_key_id == "" ? aws_kms_key.default[0].arn : var.kms_key_id
    }
  )

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "instance_kms_policy" {
  count = var.enable_managed_kms_key ? 1 : 0

  role       = var.runner_role.create_role_profile ? aws_iam_role.instance[0].name : local.aws_iam_role_instance_name
  policy_arn = aws_iam_policy.instance_kms_policy[0].arn
}


################################################################################
### Policies for runner agent instance to create docker machines via spot req.
###
### iam:PassRole To pass the role from the agent to the docker machine runners
################################################################################
resource "aws_iam_policy" "instance_docker_machine_policy" {
  count = var.runner_worker.type == "docker+machine" && var.runner_role.create_role_profile ? 1 : 0

  name        = "${local.name_iam_objects}-docker-machine"
  path        = "/"
  description = "Policy for docker machine."
  policy = templatefile("${path.module}/policies/instance-docker-machine-policy.json",
    {
      docker_machine_role_arn = aws_iam_role.docker_machine[0].arn
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "instance_docker_machine_policy" {
  count = var.runner_worker.type == "docker+machine" && var.runner_role.create_role_profile ? 1 : 0

  role       = aws_iam_role.instance[0].name
  policy_arn = aws_iam_policy.instance_docker_machine_policy[0].arn
}

################################################################################
### Policies for runner agent instance to allow connection via Session Manager
################################################################################
resource "aws_iam_policy" "instance_session_manager_policy" {
  count = var.runner_instance.ssm_access ? 1 : 0

  name        = "${local.name_iam_objects}-session-manager"
  path        = "/"
  description = "Policy session manager."
  policy      = templatefile("${path.module}/policies/instance-session-manager-policy.json", {})

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "instance_session_manager_policy" {
  count = var.runner_instance.ssm_access ? 1 : 0

  role       = var.runner_role.create_role_profile ? aws_iam_role.instance[0].name : local.aws_iam_role_instance_name
  policy_arn = aws_iam_policy.instance_session_manager_policy[0].arn
}

resource "aws_iam_role_policy_attachment" "instance_session_manager_aws_managed" {
  count = var.runner_instance.ssm_access ? 1 : 0

  role       = var.runner_role.create_role_profile ? aws_iam_role.instance[0].name : local.aws_iam_role_instance_name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

################################################################################
### Add user defined policies
################################################################################
resource "aws_iam_role_policy_attachment" "user_defined_policies" {
  count = length(var.runner_role.policy_arns)

  role       = var.runner_role.create_role_profile ? aws_iam_role.instance[0].name : local.aws_iam_role_instance_name
  policy_arn = var.runner_role.policy_arns[count.index]
}

################################################################################
### Policy for the docker machine instance to access cache
################################################################################
resource "aws_iam_role_policy_attachment" "docker_machine_cache_instance" {
  /* If the S3 cache adapter is configured to use an IAM instance profile, the
     adapter uses the profile attached to the GitLab Runner machine. So do not
     use aws_iam_role.docker_machine.name here! See https://docs.gitlab.com/runner/configuration/advanced-configuration.html */
  count = var.runner_worker_cache["create"] || lookup(var.runner_worker_cache, "policy", "") != "" ? 1 : 0

  role       = var.runner_role.create_role_profile ? aws_iam_role.instance[0].name : local.aws_iam_role_instance_name
  policy_arn = local.bucket_policy
}

################################################################################
### docker machine instance policy
################################################################################
resource "aws_iam_role" "docker_machine" {
  count                = var.runner_worker.type == "docker+machine" ? 1 : 0
  name                 = "${local.name_iam_objects}-docker-machine"
  assume_role_policy   = length(var.runner_worker_docker_machine_role.assume_role_policy_json) > 0 ? var.runner_worker_docker_machine_role.assume_role_policy_json : templatefile("${path.module}/policies/instance-role-trust-policy.json", {})
  permissions_boundary = var.iam_permissions_boundary == "" ? null : "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:policy/${var.iam_permissions_boundary}"

  tags = local.tags
}



resource "aws_iam_instance_profile" "docker_machine" {
  count = var.runner_worker.type == "docker+machine" ? 1 : 0
  name  = "${local.name_iam_objects}-docker-machine"
  role  = aws_iam_role.docker_machine[0].name
  tags  = local.tags
}

################################################################################
### Add user defined policies
################################################################################
resource "aws_iam_role_policy_attachment" "docker_machine_user_defined_policies" {
  count = var.runner_worker.type == "docker+machine" ? length(var.runner_worker_docker_machine_role.policy_arns) : 0

  role       = aws_iam_role.docker_machine[0].name
  policy_arn = var.runner_worker_docker_machine_role.policy_arns[count.index]
}

################################################################################
resource "aws_iam_role_policy_attachment" "docker_machine_session_manager_aws_managed" {
  count = (var.runner_worker.type == "docker+machine" && var.runner_worker.ssm_access) ? 1 : 0

  role       = aws_iam_role.docker_machine[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}



################################################################################
### Service linked policy, optional
################################################################################
resource "aws_iam_policy" "service_linked_role" {
  count = var.runner_role.allow_iam_service_linked_role_creation ? 1 : 0

  name        = "${local.name_iam_objects}-service_linked_role"
  path        = "/"
  description = "Policy for creation of service linked roles."
  policy      = templatefile("${path.module}/policies/service-linked-role-create-policy.json", { partition = data.aws_partition.current.partition })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "service_linked_role" {
  count = var.runner_role.allow_iam_service_linked_role_creation ? 1 : 0

  role       = var.runner_role.create_role_profile ? aws_iam_role.instance[0].name : local.aws_iam_role_instance_name
  policy_arn = aws_iam_policy.service_linked_role[0].arn
}

resource "aws_eip" "gitlab_runner" {
  # checkov:skip=CKV2_AWS_19:We can't use NAT gateway here as we are contacted from the outside.
  count = var.runner_instance.use_eip ? 1 : 0

  tags = local.tags
}

################################################################################
### AWS Systems Manager access to store runner token once registered
################################################################################
resource "aws_iam_policy" "ssm" {
  name        = "${local.name_iam_objects}-ssm"
  path        = "/"
  description = "Policy for runner token param access via SSM"
  policy      = templatefile("${path.module}/policies/instance-secure-parameter-role-policy.json", { partition = data.aws_partition.current.partition })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = var.runner_role.create_role_profile ? aws_iam_role.instance[0].name : local.aws_iam_role_instance_name
  policy_arn = aws_iam_policy.ssm.arn
}

################################################################################
### AWS assign EIP
################################################################################
resource "aws_iam_policy" "eip" {
  count = var.runner_instance.use_eip ? 1 : 0

  name        = "${local.name_iam_objects}-eip"
  path        = "/"
  description = "Policy for runner to assign EIP"
  policy      = templatefile("${path.module}/policies/instance-eip.json", {})

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "eip" {
  count = var.runner_instance.use_eip ? 1 : 0

  role       = var.runner_role.create_role_profile ? aws_iam_role.instance[0].name : local.aws_iam_role_instance_name
  policy_arn = aws_iam_policy.eip[0].arn
}

################################################################################
### Lambda function triggered as soon as an agent is terminated.
################################################################################
module "terminate_agent_hook" {
  source = "./modules/terminate-agent-hook"

  name                                 = var.runner_terminate_ec2_lifecycle_hook_name == null ? "terminate-instances" : var.runner_terminate_ec2_lifecycle_hook_name
  environment                          = var.environment
  asg_arn                              = aws_autoscaling_group.gitlab_runner_instance.arn
  asg_name                             = aws_autoscaling_group.gitlab_runner_instance.name
  cloudwatch_logging_retention_in_days = var.runner_cloudwatch.retention_days
  name_iam_objects                     = local.name_iam_objects
  name_docker_machine_runners          = local.runner_tags_merged["Name"]
  role_permissions_boundary            = var.iam_permissions_boundary == "" ? null : "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:policy/${var.iam_permissions_boundary}"
  kms_key_id                           = local.kms_key

  tags = local.tags
}

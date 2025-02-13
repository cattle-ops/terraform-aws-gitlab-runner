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
      kms_key_arn = local.kms_key_arn
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

################################################################################
### AWS Systems Manager access to store runner token once registered
################################################################################
data "aws_iam_policy_document" "ssm" {
  statement {
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
    ]
    resources = [
      for name in compact(
        [
          aws_ssm_parameter.runner_sentry_dsn.name,
          var.runner_gitlab_registration_token_secure_parameter_store_name,
          var.runner_gitlab.access_token_secure_parameter_store_name,
          var.runner_gitlab.preregistered_runner_token_ssm_parameter_name,
          aws_ssm_parameter.runner_registration_token.name
        ]
      ) : "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${trimprefix(name, "/")}"
    ]
  }

  statement {
    actions = ["ssm:PutParameter"]
    resources = [
      "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${trimprefix(aws_ssm_parameter.runner_registration_token.name, "/")}"
    ]
  }
}

resource "aws_iam_policy" "ssm" {
  name        = "${local.name_iam_objects}-ssm"
  path        = "/"
  description = "Policy for runner token param access via SSM"
  policy      = data.aws_iam_policy_document.ssm.json

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

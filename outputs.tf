output "runner_as_group_name" {
  description = "Name of the autoscaling group for the gitlab-runner instance"
  value       = aws_autoscaling_group.gitlab_runner_instance.name
}

output "runner_cache_bucket_arn" {
  description = "ARN of the S3 for the build cache."
  value       = element(concat(module.cache.*.arn, [""]), 0)
}

output "runner_cache_bucket_name" {
  description = "Name of the S3 for the build cache."
  value       = element(concat(module.cache.*.bucket, [""]), 0)
}

output "runner_agent_role_arn" {
  description = "ARN of the role used for the ec2 instance for the GitLab runner agent."
  value       = local.aws_iam_role_instance_arn
}

output "runner_agent_role_name" {
  description = "Name of the role used for the ec2 instance for the GitLab runner agent."
  value       = local.aws_iam_role_instance_name
}

output "runner_role_arn" {
  description = "ARN of the role used for the docker machine runners."
  value       = element(concat(aws_iam_role.docker_machine.*.arn, [""]), 0)
}

output "runner_role_name" {
  description = "Name of the role used for the docker machine runners."
  value       = element(concat(aws_iam_role.docker_machine.*.name, [""]), 0)
}

output "runner_agent_sg_id" {
  description = "ID of the security group attached to the GitLab runner agent."
  value       = aws_security_group.runner.id
}

output "runner_sg_id" {
  description = "ID of the security group attached to the docker machine runners."
  value       = element(concat(aws_security_group.docker_machine.*.id, [""]), 0)
}

output "runner_eip" {
  description = "EIP of the Gitlab Runner"
  value       = element(concat(aws_eip.gitlab_runner.*.public_ip, [""]), 0)
}

################################################################################
### Outputs received from config module.
################################################################################

output "config_uri" {
  value       = module.config.config_uri
  description = "S3 URI to configuration file on configuration bucket. One can pass it to s3 cp command in order to pull it."
}

output "config_bucket" {
  value       = module.config.config_bucket
  description = "Name of Gitlab runner configuration bucket."
}

output "cloudtrail_bucket" {
  value       = module.config.cloudtrail_bucket
  description = "Name of CloudTrail bucket used by automatic config updates."
}

output "runner_launch_template_name" {
  description = "The name of the runner's launch template."
  value       = aws_launch_template.gitlab_runner_instance.name
}

output "runner_user_data" {
  description = "The user data of the Gitlab Runner Agent's launch template."
  value       = local.template_user_data
}
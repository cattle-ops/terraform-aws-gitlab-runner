output "runner_as_group_name" {
  description = "Name of the autoscaling group for the gitlab-runner instance"
  value       = aws_autoscaling_group.gitlab_runner_instance.name
}

output "runner_cache_bucket_arn" {
  description = "ARN of the S3 for the build cache."
  value       = length(module.cache) > 0 ? module.cache[0].arn : null
}

output "runner_cache_bucket_name" {
  description = "Name of the S3 for the build cache."
  value       = length(module.cache) > 0 ? module.cache[0].bucket : null
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
  value       = length(aws_iam_role.docker_machine) > 0 ? aws_iam_role.docker_machine[0].arn : null
}

output "runner_role_name" {
  description = "Name of the role used for the docker machine runners."
  value       = length(aws_iam_role.docker_machine) > 0 ? aws_iam_role.docker_machine[0].name : null
}

output "runner_agent_sg_id" {
  description = "ID of the security group attached to the GitLab runner agent."
  value       = aws_security_group.runner.id
}

output "runner_sg_id" {
  description = "ID of the security group attached to the docker machine runners."
  value       = length(aws_security_group.docker_machine) > 0 ? aws_security_group.docker_machine[0].id : null
}

output "runner_eip" {
  description = "EIP of the Gitlab Runner"
  value       = length(aws_eip.gitlab_runner) > 0 ? aws_eip.gitlab_runner[0].public_ip : null
}

output "runner_launch_template_name" {
  description = "The name of the runner's launch template."
  value       = aws_launch_template.gitlab_runner_instance.name
}

output "runner_user_data" {
  description = "(Deprecated) The user data of the Gitlab Runner Agent's launch template. Set `var.debug.output_runner_user_data_to_file` to true to write `user_data.sh`."
  value       = nonsensitive(local.template_user_data)
}

output "runner_config_toml_rendered" {
  description = "The rendered config.toml given to the Runner Manager."
  value       = local.template_runner_config
}

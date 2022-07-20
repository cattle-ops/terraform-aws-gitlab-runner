output "runner_as_group_name" {
  description = "Name of the autoscaling group for the gitlab-runner instance"
  value       = aws_autoscaling_group.gitlab_runner_instance.name
}

output "runner_cache_bucket_arn" {
  description = "ARN of the S3 for the build cache."
  value       = module.cache.arn
}

output "runner_cache_bucket_name" {
  description = "Name of the S3 for the build cache."
  value       = module.cache.bucket
}

output "runner_agent_role_arn" {
  description = "ARN of the role used for the ec2 instance for the GitLab runner agent."
  value       = var.runner_iam_role_name == ""  ? aws_iam_role.instance[0].arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.runner_iam_role_name}"
}

output "runner_agent_role_name" {
  description = "Name of the role used for the ec2 instance for the GitLab runner agent."
  value       = var.runner_iam_role_name == ""  ? aws_iam_role.instance[0].name : var.runner_iam_role_name
}

output "runner_role_arn" {
  description = "ARN of the role used for the docker machine runners."
  value       = var.docker_machine_iam_role_name == ""  ? aws_iam_role.docker_machine[0].arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.docker_machine_iam_role_name}"
}

output "runner_role_name" {
  description = "Name of the role used for the docker machine runners."
  value       = var.docker_machine_iam_role_name == ""  ? aws_iam_role.docker_machine[0].name : var.docker_machine_iam_role_name
}

output "runner_agent_sg_id" {
  description = "ID of the security group attached to the GitLab runner agent."
  value       = aws_security_group.runner.id
}

output "runner_sg_id" {
  description = "ID of the security group attached to the docker machine runners."
  value       = aws_security_group.docker_machine.id
}

output "runner_eip" {
  description = "EIP of the Gitlab Runner"
  value       = element(concat(aws_eip.gitlab_runner.*.public_ip, [""]), 0)
}

output "runner_launch_template_name" {
  description = "The name of the runner's launch template."
  value       = aws_launch_template.gitlab_runner_instance.name
}
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
  value       = aws_iam_role.instance.arn
}

output "runner_agent_role_name" {
  description = "Name of the role used for the ec2 instance for the GitLab runner agent."
  value       = aws_iam_role.instance.name
}

output "runner_role_arn" {
  description = "ARN of the role used for the docker machine runners."
  value       = aws_iam_role.docker_machine.arn
}

output "runner_role_name" {
  description = "Name of the role used for the docker machine runners."
  value       = aws_iam_role.docker_machine.name
}

output "runner_agent_sg_id" {
  description = "ID of the security group attached to the GitLab runner agent."
  value       = aws_security_group.runner.id
}

output "runner_sg_id" {
  description = "ID of the security group attached to the docker machine runners."
  value       = aws_security_group.docker_machine.id
}

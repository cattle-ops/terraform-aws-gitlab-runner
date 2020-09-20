# Outputs for Docker Machine
output "dm_machine_ip" {
  value = data.aws_instance.runner.public_ip == "" ? data.aws_instance.runner.private_ip : data.aws_instance.runner.public_ip
}
output "dm_ssh_user" {
  value = "ubuntu"
}
output "dm_ssh_port" {
  value = var.dm_ssh_port
}

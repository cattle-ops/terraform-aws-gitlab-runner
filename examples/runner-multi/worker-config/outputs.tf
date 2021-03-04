# Outputs for Docker Machine
output "dm_machine_ip" {
  value = local.worker_ip
}
output "dm_ssh_user" {
  value = "ubuntu"
}
output "dm_ssh_port" {
  value = var.dm_ssh_port
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
}

resource "local_file" "public_ssh_key" {
  depends_on = [tls_private_key.ssh]

  content  = tls_private_key.ssh.public_key_openssh
  filename = var.public_ssh_key_filename
}

resource "local_file" "private_ssh_key" {
  depends_on = [tls_private_key.ssh]

  content  = tls_private_key.ssh.private_key_pem
  filename = var.private_ssh_key_filename
}

resource "null_resource" "file_permission" {
  depends_on = [local_file.private_ssh_key]

  provisioner "local-exec" {
    command     = format("chmod 600 %s", var.private_ssh_key_filename)
    interpreter = ["/bin/bash", "-c"]
  }
}


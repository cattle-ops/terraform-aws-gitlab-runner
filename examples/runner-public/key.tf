####################################
# Key Pair
####################################

locals {
  key_pair_specified      = "${var.key_pair_name == ""}"
  key_pair_write          = "${local.key_pair_specified && var.write_private_key}"
  generated_key_pair_name = "${var.environment}-gitlab-runner"
  key_pair_name           = "${ local.key_pair_specified ? local.generated_key_pair_name : var.key_pair_name }"
  key_pair_path           = "${path.module}/generated"
}

resource "tls_private_key" "this" {
  count     = "${local.key_pair_specified ? 1 : 0}"
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "aws_key_pair" "this" {
  count      = "${local.key_pair_specified ? 1 : 0}"
  key_name   = "${local.generated_key_pair_name}"
  public_key = "${tls_private_key.this.public_key_openssh}"
}

resource "local_file" "private_key" {
  count    = "${local.key_pair_write ? 1 : 0}"
  content  = "${tls_private_key.this.private_key_pem}"
  filename = "${local.key_pair_path}/${local.generated_key_pair_name}_rsa"
}

resource "null_resource" "chmod_key" {
  count      = "${local.key_pair_write ? 1 : 0}"
  depends_on = ["local_file.private_key"]

  provisioner "local-exec" {
    command = "chmod 600 ${local.key_pair_path}/${local.generated_key_pair_name}_rsa"
  }
}

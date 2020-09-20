#!/usr/bin/env sh
set -e

# Pull Terraform
curl -L "${terraform_url}" -o terraform.zip
unzip terraform.zip
chmod +x terraform
sudo mv terraform /usr/local/bin/terraform
sudo ln /usr/local/bin/terraform /bin/terraform
rm -f terraform.zip

# Pull Terraform Driver
curl -L "${terraform_driver_url}" -o terraform-driver.zip
unzip terraform-driver.zip
chmod +x docker-machine-driver-terraform
sudo mv docker-machine-driver-terraform /usr/local/bin/docker-machine-driver-terraform
sudo ln /usr/local/bin/docker-machine-driver-terraform /bin/docker-machine-driver-terraform
rm -f terraform-driver.zip

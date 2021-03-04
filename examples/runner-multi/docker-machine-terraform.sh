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

# Set up cronjob to cleanup invalid docker machines
dm_cleanup=/usr/local/bin/docker-machine-cleanup.sh
cat <<'EOF' >$dm_cleanup
#!/bin/bash
for machine in $(docker-machine ls | grep runner | grep -i error | awk '{ print $1 }'); do
  echo "Cleanup of errored machine: $machine"
  docker-machine rm -f $machine
done
EOF
chmod 755 "$dm_cleanup"

cat <<EOF >>/etc/crontab
* * * * * root $dm_cleanup >> /var/log/docker-machine-cleanup.log 2>&1
EOF

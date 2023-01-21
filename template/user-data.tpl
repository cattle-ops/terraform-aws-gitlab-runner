#!/bin/bash -e
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

if [[ $(echo ${user_data_trace_log}) == true ]]; then
  set -x
fi

# Add current hostname to hosts file
tee /etc/hosts <<EOL
127.0.0.1   localhost localhost.localdomain $(hostname)
EOL

token=$(curl -f -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 300")

${eip}

echo ""
echo "Installing AWS CLI..."
AWSCLI_LOG=/var/log/aws-cli-install.log
touch $AWSCLI_LOG

for i in {1..7}; do
  echo "Attempt: ---- " $i
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${aws_cli_version}.zip" -o "awscliv2.zip" >>$AWSCLI_LOG 2>&1 && break || sleep 60
done
unzip awscliv2.zip >>$AWSCLI_LOG 2>&1
sudo ./aws/install >>$AWSCLI_LOG 2>&1
aws --version
ln -f "$(which aws)" /bin/aws

${yum_update}

${logging}

${extra_files_sync_command}

${gitlab_runner}

${extra_config}

#!/bin/bash -ex
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1


# Add current hostname to hosts file
tee /etc/hosts <<EOL
127.0.0.1   localhost localhost.localdomain `hostname`
EOL

for i in {1..7}
do
  echo "Attempt: ---- " $i
  yum -y update  && break || sleep 60
done

yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
restart amazon-ssm-agent

${logging}

${gitlab_runner}

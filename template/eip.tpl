echo 'installing additional software for assigning EIP'
pip install aws-ec2-assign-elastic-ip
export AWS_DEFAULT_REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | awk -F\" '{print $4}')
/usr/local/bin/aws-ec2-assign-elastic-ip --valid-ips ${eip}

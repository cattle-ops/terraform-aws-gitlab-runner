echo 'installing additional software for logging'
# installing in a loop to ensure the cli is installed.
for i in {1..7}
do
  echo "Attempt: ---- " $i
  yum install -y amazon-cloudwatch-agent jq && break || sleep 60
done

CW_CONFIG=/etc/amazon/amazon-cloudwatch-agent-config.json

# Inject the CloudWatch Logs configuration file contents
cat <<-'EOF' >$CW_CONFIG
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/dmesg",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "{instance_id}/dmesg"
          },
          {
            "file_path": "/var/log/messages",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "{instance_id}/messages",
            "timestamp_format": "%b %d %H:%M:%S"
          },
          {
            "file_path": "/var/log/user-data.log",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "{instance_id}/user-data"
          }
        ]
      }
    }
  }
}
EOF

amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:$CW_CONFIG -s

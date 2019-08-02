{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "${ec2_endpoint_url}"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}

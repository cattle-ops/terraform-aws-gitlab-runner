concurrent = ${runners_concurrent}
check_interval = 0

[[runners]]
  name = "${runners_name}"
  url = "${gitlab_url}"
  token = "${runners_token}"
  executor = "docker+machine"
  limit = ${runners_limit}
  [runners.docker]
    tls_verify = false
    image = "docker:17.11.0-ce"
    privileged = ${runners_privilled}
    disable_cache = false
    volumes = ["/cache"]
    shm_size = 0
  [runners.cache]
    Type = "s3"
    ServerAddress = "s3-${aws_region}.amazonaws.com"
    AccessKey = "${bucket_user_access_key}"
    SecretKey = "${bucket_user_secret_key}"
    BucketName = "${bucket_name}"
    Insecure = false
  [runners.machine]
    IdleCount = ${runners_idle_count}
    IdleTime = ${runners_idle_time}
    MachineDriver = "amazonec2"
    MachineName = "runner-%s"
    MachineOptions = ["amazonec2-access-key=${runners_access_key}", "amazonec2-secret-key=${runners_secret_key}", "amazonec2-instance-type=${runners_instance_type}", "amazonec2-region=${aws_region}", "amazonec2-vpc-id=${runners_vpc_id}", "amazonec2-subnet-id=${runners_subnet_id}", "amazonec2-private-address-only=true", "amazonec2-request-spot-instance=true", "amazonec2-spot-price=${runners_spot_price_bid}", "amazonec2-security-group=${runners_security_group_name}", "amazonec2-tags=environment,${environment}", "amazonec2-monitoring=true"]
    OffPeakTimezone = ""
    OffPeakIdleCount = 0
    OffPeakIdleTime = 0

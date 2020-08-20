[[runners]]
  name = "${name}"
  url = "${gitlab_url}"
  token = "${token}"
  executor = "${executor}"
  environment = ${environment_vars}
  pre_build_script = "${pre_build_script}"
  post_build_script = "${post_build_script}"
  pre_clone_script = "${pre_clone_script}"
  request_concurrency = ${request_concurrency}
  output_limit = ${output_limit}
  limit = ${limit}
  [runners.docker]
    tls_verify = false
    image = "${image}"
    privileged = ${privileged}
    disable_cache = false
    volumes = ["/cache"${additional_volumes}]
    shm_size = ${shm_size}
    pull_policy = "${pull_policy}"
  [runners.docker.tmpfs]
    ${volumes_tmpfs}
  [runners.docker.services_tmpfs]
    ${services_volumes_tmpfs}
  [runners.cache]
    Type = "s3"
    Shared = ${shared_cache}
    [runners.cache.s3]
      ServerAddress = "s3.amazonaws.com"
      BucketName = "${bucket_name}"
      BucketLocation = "${aws_region}"
      Insecure = false
  [runners.machine]
    IdleCount = ${idle_count}
    IdleTime = ${idle_time}
    ${max_builds}
    MachineDriver = "amazonec2"
    MachineName = "runner-%s"
    MachineOptions = [
      "amazonec2-instance-type=${instance_type}",
      "amazonec2-region=${aws_region}",
      "amazonec2-zone=${aws_zone}",
      "amazonec2-vpc-id=${vpc_id}",
      "amazonec2-subnet-id=${subnet_id}",
      "amazonec2-private-address-only=${use_private_address_only}",
      "amazonec2-use-private-address=${use_private_address}",
      "amazonec2-request-spot-instance=${request_spot_instance}",
      "amazonec2-spot-price=${spot_price_bid}",
      "amazonec2-security-group=${security_group_name}",
      "amazonec2-tags=${tags}",
      "amazonec2-use-ebs-optimized-instance=${ebs_optimized}",
      "amazonec2-monitoring=${monitoring}",
      "amazonec2-iam-instance-profile=%{ if iam_instance_profile_name != "" }${iam_instance_profile_name}%{ else }${instance_profile}%{ endif ~}",
      "amazonec2-root-size=${root_size}",
      "amazonec2-ami=${ami}"
      ${docker_machine_options}
    ]
    OffPeakTimezone = "${off_peak_timezone}"
    OffPeakIdleCount = ${off_peak_idle_count}
    OffPeakIdleTime = ${off_peak_idle_time}
    ${off_peak_periods_string}

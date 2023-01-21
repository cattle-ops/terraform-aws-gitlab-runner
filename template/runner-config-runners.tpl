[[runners]]
  name = "${name}"
  url = "${gitlab_url}"
  clone_url = "${gitlab_clone_url}"
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
    extra_hosts = ${jsonencode(extra_hosts)}
    shm_size = ${shm_size}
    pull_policy = "${pull_policies}"
    runtime = "${docker_runtime}"
    helper_image = "${helper_image}"
    ${docker_services}
  [runners.docker.tmpfs]
    ${volumes_tmpfs}
  [runners.docker.services_tmpfs]
    ${services_volumes_tmpfs}
  [runners.cache]
    Type = "s3"
    Shared = ${shared_cache}
    [runners.cache.s3]
      AuthenticationType = "${auth_type}"
      ServerAddress = "s3.amazonaws.com"
      BucketName = "${bucket_name}"
      BucketLocation = "${aws_region}"
      Insecure = false
  [runners.machine]
    IdleCount = ${idle_count}
    IdleTime = ${idle_time}
    ${max_builds}
    MachineDriver = "amazonec2"
    MachineName = "${machine_name}"
    MachineOptions = [
%{~ if machine_driver == "amazonec2" }
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
      "amazonec2-tags=${runners_tags},__PARENT_TAG__",
      "amazonec2-use-ebs-optimized-instance=${ebs_optimized}",
      "amazonec2-monitoring=${monitoring}",
      "amazonec2-iam-instance-profile=%{ if iam_instance_profile_name != "" }${iam_instance_profile_name}%{ else }${instance_profile}%{ endif ~}",
      "amazonec2-root-size=${root_size}",
      "amazonec2-volume-type=${volume_type}",
      "amazonec2-userdata=%{ if userdata != "" }/etc/gitlab-runner/runners_userdata.sh%{ endif ~}",
      "amazonec2-ami=${ami}"%{ if machine_options != "" },%{ endif ~}
%{ endif }
${machine_options}
    ]

${machine_autoscaling}

#!/bin/sh
set -u

#
# Precondition: The module call has been extracted to a separate file given in "$1". The code is well-formatted.
#               Run `terraform fmt` to do that
#
# $1: file name containing the module call to be converted
#

converted_file="$1.new"

cp "$1" "$converted_file"

#
# PR #738 chore!: remove deprecated variables
#
sed -i '/arn_format/d' "$converted_file"
sed -i '/subnet_ids_gitlab_runner/d' "$converted_file"
sed -i '/asg_terminate_lifecycle_hook_create/d' "$converted_file"
sed -i '/asg_terminate_lifecycle_hook_heartbeat_timeout/d' "$converted_file"
sed -i '/asg_terminate_lifecycle_lambda_memory_size/d' "$converted_file"
sed -i '/asg_terminate_lifecycle_lambda_runtime/d' "$converted_file"
sed -i '/asg_terminate_lifecycle_lambda_timeout/d' "$converted_file"

#
#  PR #711 feat!: refactor Docker Machine autoscaling options
#
sed -i 's/runners_machine_autoscaling/runners_machine_autoscaling_options/g' "$converted_file"

#
# PR #710 chore!: remove old variable `runners_pull_policy`
#
sed -i '/runners_pull_policy/d' "$converted_file"

#
# PR #511 feat!: allow to set all docker options for the Executor
#
extracted_variables=$(grep -E '(runners_pull_policies|runners_docker_runtime|runners_helper_image|runners_shm_size|runners_shm_size|runners_extra_hosts|runners_disable_cache|runners_image|runners_privileged)' "$converted_file")

sed -i '/runners_image/d' "$converted_file"
sed -i '/runners_privileged/d' "$converted_file"
sed -i '/runners_disable_cache/d' "$converted_file"
sed -i '/runners_extra_hosts/d' "$converted_file"
sed -i '/runners_shm_size/d' "$converted_file"
sed -i '/runners_docker_runtime/d' "$converted_file"
sed -i '/runners_helper_image/d' "$converted_file"
sed -i '/runners_pull_policies/d' "$converted_file"

# content to be added to `volumes`
volumes=$(grep "runners_additional_volumes" "$converted_file" | cut -d '=' -f 2 | tr -d '[]')

if [ -n "$volumes" ]; then
  extracted_variables="$extracted_variables
    volumes = [\"/cache\", $volumes]"
fi

sed -i '/runners_additional_volumes/d' "$converted_file"


# rename the variables
extracted_variables=$(echo "$extracted_variables" | \
                      sed 's/runners_image/image/g' | \
                      sed 's/runners_privileged/privileged/g' | \
                      sed 's/runners_disable_cache/disable_cache/g' | \
                      sed 's/runners_extra_hosts/extra_hosts/g' | \
                      sed 's/runners_shm_size/shm_size/g' | \
                      sed 's/runners_docker_runtime/runtime/g' | \
                      sed 's/runners_helper_image/helper_image/g' | \
                      sed 's/runners_pull_policies/pull_policies/g'
                    )

# add new block runners_docker_options at the end
if [ -n "$extracted_variables" ]; then
  echo "$(head -n -1 "$converted_file")
  runner_worker_docker_options = {
    $extracted_variables
  }
  " > x && mv x "$converted_file"
fi

#
# PR #757 refactor!: rename variables and prefix with agent, executor and global scope
#
sed -i '/aws_region/d' "$converted_file"
sed -i '/enable_manage_gitlab_token/d' "$converted_file"

sed 's/enable_kms/enable_managed_kms_key/g' "$converted_file" | \
sed 's/kms_alias_name/kms_managed_alias_name/g' | \
sed 's/kms_deletion_window_in_days/kms_managed_deletion_rotation_window_in_days/g' | \
sed 's/permission_boundary/iam_permission_boundary/g' | \
sed 's/extra_security_group_ids_runner_agent/runner_extra_security_group_ids/g' | \
sed 's/instance_type/runner_instance_type/g' | \
sed 's/runner_instance_ebs_optimized/runner_ebs_optimized/g' | \
sed 's/runner_instance_enable_monitoring/runner_enable_monitoring/g' | \
sed 's/runner_instance_metadata_options/runner_metadata_options/g' | \
sed 's/runners_userdata/runner_worker_docker_machine_userdata/g' | \
sed 's/runners_executor/runner_worker_type/g' | \
sed 's/runners_install_amazon_ecr_credential_helper/runner_install_amazon_ecr_credential_helper/g' | \
sed 's/runners_clone_url/runner_gitlab_clone_url/g' | \
sed 's/runners_gitlab_url/runner_gitlab_url/g' | \
sed 's/runners_max_builds/runner_worker_docker_machine_max_builds/g' | \
sed 's/runners_idle_count/runner_worker_idle_count/g' | \
sed 's/runners_idle_time/runner_worker_idle_time/g' | \
sed 's/runners_concurrent/runner_manager_maximum_concurrent_jobs/g' | \
sed 's/runners_limit/runner_worker_max_jobs/g' | \
sed 's/runners_check_interval/runner_manager_gitlab_check_interval/g' | \
sed 's/sentry_dsn/runner_manager_sentry_dsn/g' | \
sed 's/prometheus_listen_address/runner_manager_prometheus_listen_address/g' | \
sed 's/runner_extra_config/runner_user_data_extra/g' | \
sed 's/runners_ca_certificate/runner_gitlab_ca_certificate/g' | \
sed 's/runners_yum_update/runner_yum_update/g' | \
sed 's/runners_gitlab_certificate/runners_gitlab_certificate/g' | \
sed 's/asg_terminate_lifecycle_hook_name/runner_terminate_ec2_lifecycle_hook_name/g' | \
sed 's/runner_iam_policy_arns/runner_extra_iam_policy_arns/g' | \
sed 's/create_runner_iam_role/runner_create_runner_iam_role_profile/g' | \
sed 's/runner_iam_role_name/runner_iam_role_profile_name/g' | \
sed 's/enable_eip/runner_enable_eip/g' | \
sed 's/enable_runner_ssm_access/runner_enable_ssm_access/g' | \
sed 's/enable_runner_user_data_trace_log/runner_user_data_enable_trace_log/g' | \
sed 's/enable_schedule/runner_schedule_enable/g' | \
sed 's/schedule_config/runner_schedule_config/g' | \
sed 's/runner_root_block_device/runner_root_block_device/g' | \
sed 's/gitlab_runner_registration_config/runner_gitlab_registration_config/g' | \
sed 's/[^_]ami_filter/runner_ami_filter/g' | \
sed 's/[^_]ami_owners/runner_ami_owners/g' | \
sed 's/runner_ami_filter/runner_worker_docker_machine_ami_filter/g' | \
sed 's/runner_ami_owners/runner_worker_docker_machine_ami_owners/g' | \
sed 's/instance_role_json/runner_assume_role_json/g' | \
sed 's/docker_machine_role_json/runner_worker_docker_machine_assume_role_json/g' | \
sed 's/role_tags/runner_extra_role_tags/g' | \
sed 's/runner_tags/runner_worker_docker_machine_extra_role_tags/g' | \
sed 's/agent_tags/runner_extra_instance_tags/g' | \
sed 's/enable_ping/runner_ping_enable/g' | \
sed 's/[^\.]gitlab_runner_version/runner_gitlab_runner_version/g' | \
sed 's/gitlab_runner_egress_rules/runner_extra_egress_rules/g' | \
sed 's/gitlab_runner_security_group_ids/runner_ping_allow_from_security_groups/g' | \
sed 's/gitlab_runner_security_group_description/runner_security_group_description/g' | \
sed 's/cache_shared/runner_worker_cache_shared/g' | \
sed 's/cache_expiration_days/runner_worker_cache_s3_expiration_days/g' | \
sed 's/cache_bucket_versioning/runner_worker_cache_s3_enable_versioning/g' | \
sed 's/cache_logging_bucket_prefix/runner_worker_cache_s3_logging_bucket_prefix/g' | \
sed 's/cache_logging_bucket/runner_worker_cache_s3_logging_bucket_id/g' | \
sed 's/cache_bucket_set_random_suffix/runner_worker_cache_s3_bucket_enable_random_suffix/g' | \
sed 's/cache_bucket_name_include_account_id/runner_worker_cache_s3_bucket_name_include_account_id/g' | \
sed 's/cache_bucket_prefix/runner_worker_cache_s3_bucket_prefix/g' | \
sed 's/runner_agent_uses_private_address/runner_use_private_address/g' | \
sed 's/runners_use_private_address/runner_worker_docker_machine_use_private_address/g' | \
sed 's/runners_request_spot_instance/runner_worker_docker_machine_request_spot_instances/g' | \
sed 's/userdata_pre_install/runner_userdata_pre_install/g' | \
sed 's/userdata_post_install/runner_userdata_post_install/g' | \
sed 's/runners_pre_build_script/runner_worker_pre_build_script/g' | \
sed 's/runners_post_build_script/runner_worker_post_build_script/g' | \
sed 's/runners_pre_clone_script/runner_worker_pre_clone_script/g' | \
sed 's/runners_request_concurrency/runner_worker_request_concurrency/g' | \
sed 's/runners_output_limit/runner_worker_output_limit/g' | \
sed 's/runners_environment_vars/runner_worker_extra_environment_variables/g' | \
sed 's/runners_docker_registry_mirror/runner_worker_docker_machine_docker_registry_mirror_url/g' | \
sed 's/docker_machine_egress_rules/runner_worker_docker_machine_extra_egress_rules/g' | \
sed 's/docker_machine_iam_policy_arns/runner_worker_docker_machine_extra_iam_policy_arns/g' | \
sed 's/enable_cloudwatch_logging/runner_cloudwatch_enable/g' | \
sed 's/cloudwatch_logging_retention_in_days/runner_cloudwatch_retention_days/g' | \
sed 's/log_group_name/runner_cloudwatch_log_group_name/g' | \
sed 's/asg_max_instance_lifetime/runner_max_instance_lifetime_seconds/g' | \
sed 's/asg_delete_timeout/runner_terraform_timeout_delete_asg/g' | \
sed 's/enable_docker_machine_ssm_access/runner_worker_enable_ssm_access/g' | \
sed 's/ cache_bucket/ runner_worker_cache_s3_bucket/g' | \
sed 's/docker_machine_security_group_description/runner_worker_docker_machine_security_group_description/g' | \
sed 's/docker_machine_options/runner_worker_docker_machine_ec2_options/g' | \
sed 's/runners_iam_instance_profile_name/runner_worker_docker_machine_iam_instance_profile_name/g' | \
sed 's/runners_volume_type/runner_worker_docker_machine_ec2_volume_type/g' | \
sed 's/runners_ebs_optimized/runner_worker_docker_machine_ec2_ebs_optimized/g' | \
sed 's/runners_monitoring/runner_worker_docker_machine_enable_monitoring/g' | \
sed 's/runners_machine_autoscaling_options/runner_worker_docker_machine_autoscaling_options/g' | \
sed 's/runners_docker_services/runner_worker_docker_services/g' | \
sed 's/runners_services_volumes_tmpfs/runner_worker_docker_services_volumes_tmpfs/g' | \
sed 's/runners_volumes_tmpfs/runner_worker_docker_volumes_tmpfs/g' | \
sed 's/runners_root_size/runner_worker_docker_machine_ec2_root_size/g' | \
sed 's/enable_asg_recreation/runner_enable_asg_recreation/g' | \
sed 's/secure_parameter_store_runner_sentry_dsn/runner_sentry_secure_parameter_store_name/g' | \
sed 's/secure_parameter_store_runner_token_key/runner_gitlab_token_secure_parameter_store/g' | \
sed 's/secure_parameter_store_gitlab_runner_registration_token_name/runner_gitlab_registration_token_secure_parameter_store_name/g' | \
sed 's/allow_iam_service_linked_role_creation/runner_allow_iam_service_linked_role_creation/g' | \
sed 's/runners_add_dind_volumes/runner_worker_docker_add_dind_volumes/g' | \
sed 's/runners_token/runner_gitlab_token/g' | \
sed 's/runners_name/runner_gitlab_runner_name/g' | \
sed 's/docker_machine_version/runner_docker_machine_version/g' | \
sed 's/docker_machine_download_url/runner_docker_machine_download_url/g' | \
sed 's/docker_machine_spot_price_bid/runner_worker_docker_machine_ec2_spot_price_bid/g' | \
sed 's/docker_machine_instance_type/runner_worker_docker_machine_instance_type/g' | \
sed 's/docker_machine_instance_metadata_options/runner_worker_docker_machine_ec2_metadata_options/g' | \
sed 's/runner_instance_spot_price/runner_spot_price/g' | \
sed 's/metrics_autoscaling/runner_collect_autoscaling_metrics/g' | \
sed 's/auth_type_cache_sr/runner_worker_cache_s3_authentication_type/g' \
> "$converted_file.tmp" && mv "$converted_file.tmp" "$converted_file"

# overrides block
extracted_variables=$(grep -E '(name_sg|name_iam_objects|name_runner_agent_instance|name_docker_machine_runners)' "$converted_file")

extracted_variables=$(echo "$extracted_variables" | \
                      sed 's/name_sg/security_group_prefix/g' | \
                      sed 's/name_iam_objects/iam_object_prefix/g' | \
                      sed 's/name_runner_agent_instance/runner_instance_prefix/g' | \
                      sed 's/name_docker_machine_runners/runner_worker_docker_machine_instance_prefix/g'
                    )

sed '/name_sg/d' "$converted_file" | \
sed '/name_iam_objects/d' | \
sed '/name_runner_agent_instance/d' | \
sed '/name_docker_machine_runners/d' | \
sed '/overrides = {/d' \
> "$converted_file.tmp" && mv "$converted_file.tmp" "$converted_file"

if [ -n "$extracted_variables" ]; then
  echo "$(head -n -1 "$converted_file")
    $extracted_variables
  }" > "$converted_file.tmp" && mv "$converted_file.tmp" "$converted_file"
fi

#
# PR #810 refactor!: group variables for better overview
#
extracted_variables=$(grep -E '(runner_max_instance_lifetime_seconds|runner_enable_eip|runner_collect_autoscaling_metrics|runner_enable_monitoring|runner_gitlab_runner_name|runner_enable_ssm_access|runner_use_private_address|runner_root_block_device|runner_ebs_optimized|runner_spot_price|runner_instance_prefix|runner_instance_type|runner_extra_instance_tags)' "$converted_file")

sed -i '/runner_root_block_device/d' "$converted_file"
sed -i '/runner_ebs_optimized/d' "$converted_file"
sed -i '/runner_spot_price/d' "$converted_file"
sed -i '/runner_instance_prefix/d' "$converted_file"
sed -i '/runner_instance_type/d' "$converted_file"
sed -i '/runner_extra_instance_tags/d' "$converted_file"
sed -i '/runner_use_private_address/d' "$converted_file"
sed -i '/runner_enable_ssm_access/d' "$converted_file"
sed -i '/runner_gitlab_runner_name/d' "$converted_file"
sed -i '/runner_enable_monitoring/d' "$converted_file"
sed -i '/runner_collect_autoscaling_metrics/d' "$converted_file"
sed -i '/runner_enable_eip/d' "$converted_file"
sed -i '/runner_max_instance_lifetime_seconds/d' "$converted_file"

# rename the variables
extracted_variables=$(echo "$extracted_variables" | \
                      sed 's/runner_root_block_device/root_device_config/g' | \
                      sed 's/runner_ebs_optimized/ebs_optimized/g' | \
                      sed 's/runner_spot_price/spot_price/g' | \
                      sed 's/runner_instance_prefix/name_prefix/g' | \
                      sed 's/runner_instance_type/type/g' | \
                      sed 's/runner_extra_instance_tags/additional_tags/g' | \
                      sed 's/runner_use_private_address/private_address_only/g' | \
                      sed 's/runner_gitlab_runner_name/name/g' | \
                      sed 's/runner_enable_monitoring/monitoring/g' | \
                      sed 's/runner_collect_autoscaling_metrics/collect_autoscaling_metrics/g' | \
                      sed 's/runner_enable_eip/use_eip/g' | \
                      sed 's/runner_max_instance_lifetime_seconds/max_lifetime_seconds/g' | \
                      sed 's/runner_enable_ssm_access/ssm_access/g'
                    )

# add new block runners_docker_options at the end
if [ -n "$extracted_variables" ]; then
  echo "$(head -n -1 "$converted_file")
  runner_instance = {
    $extracted_variables
  }
  " > x && cp x "$converted_file"
fi

extracted_variables=$(grep -E '(runner_allow_iam_service_linked_role_creation|runner_create_runner_iam_role_profile|runner_iam_role_profile_name|runner_extra_role_tags|runner_assume_role_json)|runner_extra_iam_policy_arns)' "$converted_file")

sed -i '/runner_allow_iam_service_linked_role_creation/d' "$converted_file"
sed -i '/runner_create_runner_iam_role_profile/d' "$converted_file"
sed -i '/runner_iam_role_profile_name/d' "$converted_file"
sed -i '/runner_extra_role_tags/d' "$converted_file"
sed -i '/runner_assume_role_json/d' "$converted_file"
sed -i '/runner_extra_iam_policy_arns/d' "$converted_file"

# rename the variables
extracted_variables=$(echo "$extracted_variables" | \
                      sed 's/runner_allow_iam_service_linked_role_creation/allow_iam_service_linked_role_creation/g' | \
                      sed 's/runner_create_runner_iam_role_profile/create_role_profile/g' | \
                      sed 's/runner_iam_role_profile_name/role_profile_name/g' | \
                      sed 's/runner_extra_role_tags/additional_tags/g' | \
                      sed 's/runner_assume_role_json/assume_role_policy_json/g' | \
                      sed 's/runner_extra_iam_policy_arns/policy_arns/g'
                    )

# add new block runners_docker_options at the end
if [ -n "$extracted_variables" ]; then
  echo "$(head -n -1 "$converted_file")
  runner_role = {
    $extracted_variables
  }
  " > x && mv x "$converted_file"
fi

extracted_variables=$(grep -E '(runner_manager_maximum_concurrent_jobs|runner_manager_sentry_dsn|runner_manager_gitlab_check_interval|runner_manager_prometheus_listen_address)' "$converted_file")

sed -i '/runner_manager_maximum_concurrent_jobs/d' "$converted_file"
sed -i '/runner_manager_sentry_dsn/d' "$converted_file"
sed -i '/runner_manager_gitlab_check_interval/d' "$converted_file"
sed -i '/runner_manager_prometheus_listen_address/d' "$converted_file"

# rename the variables
extracted_variables=$(echo "$extracted_variables" | \
                      sed 's/runner_manager_maximum_concurrent_jobs/maximum_concurrent_jobs/g' | \
                      sed 's/runner_manager_sentry_dsn/sentry_dsn/g' | \
                      sed 's/runner_manager_gitlab_check_interval/gitlab_check_interval/g' | \
                      sed 's/runner_manager_prometheus_listen_address/prometheus_listen_address/g'
                    )

# add new block runners_docker_options at the end
if [ -n "$extracted_variables" ]; then
  echo "$(head -n -1 "$converted_file")
  runner_manager = {
    $extracted_variables
  }
  " > x && mv x "$converted_file"
fi

extracted_variables=$(grep -E '(runner_yum_update|runner_user_data_extra|runner_userdata_post_install|runner_userdata_pre_install|runner_install_amazon_ecr_credential_helper|runner_docker_machine_version|runner_docker_machine_download_url)' "$converted_file")

sed -i '/runner_docker_machine_download_url/d' "$converted_file"
sed -i '/runner_docker_machine_version/d' "$converted_file"
sed -i '/runner_install_amazon_ecr_credential_helper/d' "$converted_file"
sed -i '/runner_userdata_pre_install/d' "$converted_file"
sed -i '/runner_userdata_post_install/d' "$converted_file"
sed -i '/runner_user_data_extra/d' "$converted_file"
sed -i '/runner_yum_update/d' "$converted_file"


# rename the variables
extracted_variables=$(echo "$extracted_variables" | \
                      sed 's/runner_docker_machine_download_url/docker_machine_download_url/g' | \
                      sed 's/runner_docker_machine_version/docker_machine_version/g' | \
                      sed 's/runner_install_amazon_ecr_credential_helper/amazon_ecr_credential_helper/g' | \
                      sed 's/runner_userdata_pre_install/pre_install_script/g' | \
                      sed 's/runner_userdata_post_install/post_install_script/g' | \
                      sed 's/runner_user_data_extra/start_script/g' | \
                      sed 's/runner_yum_update/yum_update/g'
                    )

# add new block runners_docker_options at the end
if [ -n "$extracted_variables" ]; then
  echo "$(head -n -1 "$converted_file")
  runner_install = {
    $extracted_variables
  }
  " > x && mv x "$converted_file"
fi

extracted_variables=$(grep -E '(runner_gitlab_clone_url|runner_gitlab_url|runner_gitlab_runner_version|runner_gitlab_token|runner_gitlab_certificate|runner_gitlab_ca_certificate)' "$converted_file")

sed -i '/runner_gitlab_ca_certificate/d' "$converted_file"
sed -i '/runner_gitlab_certificate/d' "$converted_file"
sed -i '/runner_gitlab_token/d' "$converted_file"
sed -i '/runner_gitlab_runner_version/d' "$converted_file"
sed -i '/runner_gitlab_url/d' "$converted_file"
sed -i '/runner_gitlab_clone_url/d' "$converted_file"


# rename the variables
extracted_variables=$(echo "$extracted_variables" | \
                      sed 's/runner_gitlab_ca_certificate/ca_certificate/g' | \
                      sed 's/runner_gitlab_certificate/certificate/g' | \
                      sed 's/runner_gitlab_token/registration_token/g' | \
                      sed 's/runner_gitlab_runner_version/runner_version/g' | \
                      sed 's/runner_gitlab_url/url/g' | \
                      sed 's/runner_gitlab_clone_url/url_clone/g'
                    )

# add new block runners_docker_options at the end
if [ -n "$extracted_variables" ]; then
  echo "$(head -n -1 "$converted_file")
  runner_gitlab = {
    $extracted_variables
  }
  " > x && mv x "$converted_file"
fi

extracted_variables=$(grep -E '(show_user_data_in_plan|runner_user_data_enable_trace_log)' "$converted_file")

sed -i '/runner_user_data_enable_trace_log/d' "$converted_file"
sed -i '/show_user_data_in_plan/d' "$converted_file"

# rename the variables
extracted_variables=$(echo "$extracted_variables" | \
                      sed 's/runner_user_data_enable_trace_log/trace_runner_user_data/g' | \
                      sed 's/show_user_data_in_plan/write_runner_config_to_file/g'
                    )

# add new block runners_docker_options at the end
if [ -n "$extracted_variables" ]; then
  echo "$(head -n -1 "$converted_file")
  debug = {
    $extracted_variables
  }
  " > x && mv x "$converted_file"
fi

sed -i 's/output_runner_user_data_to_file/write_runner_user_data_to_file/g' "$converted_file"

extracted_variables=$(grep -E '(runner_cloudwatch_log_group_name|runner_cloudwatch_retention_days|runner_cloudwatch_enable)' "$converted_file")

sed -i '/runner_cloudwatch_enable/d' "$converted_file"
sed -i '/runner_cloudwatch_retention_days/d' "$converted_file"
sed -i '/runner_cloudwatch_log_group_name/d' "$converted_file"

# rename the variables
extracted_variables=$(echo "$extracted_variables" | \
                      sed 's/runner_cloudwatch_enable/enable/g' | \
                      sed 's/runner_cloudwatch_retention_days/retention_days/g' | \
                      sed 's/runner_cloudwatch_log_group_name/log_group_name/g'
                    )

# add new block runners_docker_options at the end
if [ -n "$extracted_variables" ]; then
  echo "$(head -n -1 "$converted_file")
  runner_cloudwatch = {
    $extracted_variables
  }
  " > x && mv x "$converted_file"
fi

extracted_variables=$(grep -E '(runner_worker_extra_environment_variables|runner_worker_output_limit|runner_worker_request_concurrency|runner_worker_max_jobs|runner_worker_type|runner_worker_enable_ssm_access)' "$converted_file")

sed -i '/runner_worker_enable_ssm_access/d' "$converted_file"
sed -i '/runner_worker_type/d' "$converted_file"
sed -i '/runner_worker_max_jobs/d' "$converted_file"
sed -i '/runner_worker_request_concurrency/d' "$converted_file"
sed -i '/runner_worker_output_limit/d' "$converted_file"
sed -i '/runner_worker_extra_environment_variables/d' "$converted_file"

# rename the variables
extracted_variables=$(echo "$extracted_variables" | \
                      sed 's/runner_worker_enable_ssm_access/ssm_access/g' | \
                      sed 's/runner_worker_max_jobs/max_jobs/g' | \
                      sed 's/runner_worker_request_concurrency/request_concurrency/g' | \
                      sed 's/runner_worker_output_limit/output_limit/g' | \
                      sed 's/runner_worker_extra_environment_variables/environment_variables/g' | \
                      sed 's/runner_worker_type/type/g'
                    )

# add new block runners_docker_options at the end
if [ -n "$extracted_variables" ]; then
  echo "$(head -n -1 "$converted_file")
  runner_worker = {
    $extracted_variables
  }
  " > x && mv x "$converted_file"
fi

# renames the block
sed -i 's/runner_worker_cache_s3_bucket /runner_worker_cache /g' "$converted_file"

# integrate the new variables into existing block
extracted_variables=$(grep -E '(runner_worker_cache_s3_logging_bucket_prefix|runner_worker_cache_s3_logging_bucket_id|runner_worker_cache_s3_bucket_enable_random_suffix|runner_worker_cache_s3_bucket_name_include_account_id|runner_worker_cache_s3_bucket_prefix|runner_worker_cache_s3_enable_versioning|runner_worker_cache_s3_expiration_days|runner_worker_cache_s3_authentication_type|runner_worker_cache_shared)' "$converted_file")

sed -i '/runner_worker_cache_shared/d' "$converted_file"
sed -i '/runner_worker_cache_s3_authentication_type/d' "$converted_file"
sed -i '/runner_worker_cache_s3_expiration_days/d' "$converted_file"
sed -i '/runner_worker_cache_s3_enable_versioning/d' "$converted_file"
sed -i '/runner_worker_cache_s3_bucket_prefix/d' "$converted_file"
sed -i '/runner_worker_cache_s3_bucket_name_include_account_id/d' "$converted_file"
sed -i '/runner_worker_cache_s3_bucket_enable_random_suffix/d' "$converted_file"
sed -i '/runner_worker_cache_s3_logging_bucket_id/d' "$converted_file"
sed -i '/runner_worker_cache_s3_logging_bucket_prefix/d' "$converted_file"

# rename the variables
extracted_variables=$(echo "$extracted_variables" | \
                      sed 's/runner_worker_cache_shared/shared/g' | \
                      sed 's/runner_worker_cache_s3_authentication_type/authentication_type/g' | \
                      sed 's/runner_worker_cache_s3_expiration_days/expiration_days/g' | \
                      sed 's/runner_worker_cache_s3_enable_versioning/versioning/g' | \
                      sed 's/runner_worker_cache_s3_bucket_prefix/bucket_prefix/g' | \
                      sed 's/runner_worker_cache_s3_bucket_name_include_account_id/include_account_id/g' | \
                      sed 's/runner_worker_cache_s3_bucket_enable_random_suffix/random_suffix/g' | \
                      sed 's/runner_worker_cache_s3_logging_bucket_id/access_log_bucket_id/g' | \
                      sed 's/runner_worker_cache_s3_logging_bucket_prefix/access_log_bucket_prefix/g'
                    )

# insert the new variables into the existing block or append new block
if [ -n "$extracted_variables" ]; then
  if grep -q "runner_worker_cache = {" "$converted_file"; then
    cp "$converted_file" "$converted_file.bak"
    sed -i "s/runner_worker_cache = {/runner_worker_cache = { $extracted_variables/g" "$converted_file"
  else
    echo "$(head -n -1 "$converted_file")
    runner_worker_cache = {
      $extracted_variables
    }
    " > x && mv x "$converted_file"
  fi
fi

extracted_variables=$(grep -E '(runner_worker_idle_count|runner_worker_idle_time|runner_worker_docker_machine_use_private_address|runner_worker_docker_machine_instance_type|runner_worker_docker_machine_docker_registry_mirror_url|runner_worker_docker_machine_max_builds|runner_worker_docker_machine_ec2_ebs_optimized|runner_worker_docker_machine_ec2_root_size|runner_worker_docker_machine_ec2_volume_type|runner_worker_docker_machine_userdata|runner_worker_docker_machine_enable_monitoring|runner_worker_enable_ssm_access|runner_worker_docker_machine_instance_prefix)' "$converted_file")

sed -i '/runner_worker_enable_ssm_access/d' "$converted_file"
sed -i '/runner_worker_docker_machine_instance_prefix/d' "$converted_file"
sed -i '/runner_worker_docker_machine_enable_monitoring/d' "$converted_file"
sed -i '/runner_worker_docker_machine_userdata/d' "$converted_file"
sed -i '/runner_worker_docker_machine_ec2_volume_type/d' "$converted_file"
sed -i '/runner_worker_docker_machine_ec2_root_size/d' "$converted_file"
sed -i '/runner_worker_docker_machine_ec2_ebs_optimized/d' "$converted_file"
sed -i '/runner_worker_docker_machine_max_builds/d' "$converted_file"
sed -i '/runner_worker_docker_machine_docker_registry_mirror_url/d' "$converted_file"
sed -i '/runner_worker_docker_machine_use_private_address/d' "$converted_file"
sed -i '/runner_worker_docker_machine_instance_type/d' "$converted_file"
sed -i '/runner_worker_idle_time/d' "$converted_file"
sed -i '/runner_worker_idle_count/d' "$converted_file"

# rename the variables
extracted_variables=$(echo "$extracted_variables" | \
                      sed 's/runner_worker_docker_machine_use_private_address/private_address_only/g' | \
                      sed 's/runner_worker_docker_machine_enable_monitoring/monitoring/g' | \
                      sed 's/runner_worker_docker_machine_userdata/start_script/g' | \
                      sed 's/runner_worker_docker_machine_ec2_volume_type/volume_type/g' | \
                      sed 's/runner_worker_docker_machine_ec2_root_size/root_size/g' | \
                      sed 's/runner_worker_docker_machine_ec2_ebs_optimized/ebs_optimized/g' | \
                      sed 's/runner_worker_docker_machine_max_builds/destroy_after_max_builds/g' | \
                      sed 's/runner_worker_docker_machine_docker_registry_mirror_url/docker_registry_mirror_url/g' | \
                      sed 's/runner_worker_docker_machine_instance_type/types/g' | \
                      sed 's/runner_worker_idle_time/idle_time/g' | \
                      sed 's/runner_worker_idle_count/idle_count/g' | \
                      sed 's/runner_worker_docker_machine_instance_prefix/name_prefix/g'
                    )

extracted_fleet_types=$(grep -E '(docker_machine_types_fleet)' "$converted_file" | sed 's/docker_machine_types_fleet/types/g')
extracted_fleet_subnets=$(grep -E '(fleet_executor_subnet_ids)' "$converted_file" | sed 's/fleet_executor_subnet_ids/subnet_ids/g')
sed -i '/docker_machine_types_fleet/d' "$converted_file"
sed -i '/fleet_executor_subnet_ids/d' "$converted_file"

# add new block runners_docker_options at the end
if [ -n "$extracted_variables" ]; then
  echo "$(head -n -1 "$converted_file")
  runner_worker_docker_machine_instance = {
    $extracted_variables
    $extracted_fleet_types
    $extracted_fleet_subnets
  }
  " > x && mv x "$converted_file"
fi

extracted_variables=$(grep -E '(runner_worker_docker_machine_request_spot_instances|runner_worker_docker_machine_ec2_spot_price_bid)' "$converted_file")

sed -i '/runner_worker_docker_machine_ec2_spot_price_bid/d' "$converted_file"
sed -i '/runner_worker_docker_machine_request_spot_instances/d' "$converted_file"

# rename the variables
extracted_variables=$(echo "$extracted_variables" | \
                      sed 's/runner_worker_docker_machine_ec2_spot_price_bid/max_price/g' | \
                      sed 's/runner_worker_docker_machine_request_spot_instances/enable/g'
                    )

# add new block runners_docker_options at the end
if [ -n "$extracted_variables" ]; then
  echo "$(head -n -1 "$converted_file")
  runner_worker_docker_machine_instance_spot = {
    $extracted_variables
  }
  " > x && mv x "$converted_file"
fi

extracted_variables=$(grep -E '(runner_extra_security_group_ids|runner_security_group_description|runner_ping_allow_from_security_groups|runner_ping_enable)' "$converted_file")

sed -i '/runner_ping_enable/d' "$converted_file"
sed -i '/runner_ping_allow_from_security_groups/d' "$converted_file"
sed -i '/runner_security_group_description/d' "$converted_file"
sed -i '/runner_extra_security_group_ids/d' "$converted_file"

# rename the variables
extracted_variables=$(echo "$extracted_variables" | \
                      sed 's/runner_ping_enable/allow_incoming_ping/g' | \
                      sed 's/runner_security_group_description/security_group_description/g' | \
                      sed 's/runner_extra_security_group_ids/security_group_ids/g' | \
                      sed 's/runner_ping_allow_from_security_groups/allow_incoming_ping_security_group_ids/g'
                    )

# add new block runners_docker_options at the end
if [ -n "$extracted_variables" ]; then
  echo "$(head -n -1 "$converted_file")
  runner_networking = {
    $extracted_variables
  }
  " > x && mv x "$converted_file"
fi

sed -i 's/runner_extra_egress_rules/runner_networking_egress_rules/g' "$converted_file"

extracted_variables=$(grep -E '(runner_worker_post_build_script|runner_worker_pre_build_script|runner_worker_pre_clone_script)' "$converted_file")

sed -i '/runner_worker_pre_clone_script/d' "$converted_file"
sed -i '/runner_worker_pre_build_script/d' "$converted_file"
sed -i '/runner_worker_post_build_script/d' "$converted_file"

# rename the variables
extracted_variables=$(echo "$extracted_variables" | \
                      sed 's/runner_worker_pre_clone_script/pre_clone_script/g' | \
                      sed 's/runner_worker_pre_build_script/pre_build_script/g' | \
                      sed 's/runner_worker_post_build_script/post_build_script/g'
                    )

# add new block runners_docker_options at the end
if [ -n "$extracted_variables" ]; then
  echo "$(head -n -1 "$converted_file")
  runner_worker_gitlab_pipeline = {
    $extracted_variables
  }
  " > x && mv x "$converted_file"
fi

extracted_variables=$(grep -E '(runner_worker_docker_machine_extra_iam_policy_arns|runner_worker_docker_machine_assume_role_json|runner_worker_docker_machine_iam_instance_profile_name|runner_worker_docker_machine_extra_role_tags)' "$converted_file")

sed -i '/runner_worker_docker_machine_extra_role_tags/d' "$converted_file"
sed -i '/runner_worker_docker_machine_iam_instance_profile_name/d' "$converted_file"
sed -i '/runner_worker_docker_machine_assume_role_json/d' "$converted_file"
sed -i '/runner_worker_docker_machine_extra_iam_policy_arns/d' "$converted_file"

# rename the variables
extracted_variables=$(echo "$extracted_variables" | \
                      sed 's/runner_worker_docker_machine_iam_instance_profile_name/profile_name/g' | \
                      sed 's/runner_worker_docker_machine_assume_role_json/assume_role_policy_json/g' | \
                      sed 's/runner_worker_docker_machine_extra_iam_policy_arns/policy_arns/g' | \
                      sed 's/runner_worker_docker_machine_extra_role_tags/additional_tags/g'
                    )

# add new block runners_docker_options at the end
if [ -n "$extracted_variables" ]; then
  echo "$(head -n -1 "$converted_file")
  runner_worker_docker_machine_role = {
    $extracted_variables
  }
  " > x && mv x "$converted_file"
fi

extracted_variables=$(grep -E '(use_fleet|fleet_key_pair_name)' "$converted_file")

sed -i '/use_fleet/d' "$converted_file"
sed -i '/fleet_key_pair_name/d' "$converted_file"

# rename the variables
extracted_variables=$(echo "$extracted_variables" | \
                      sed 's/use_fleet/enable/g' | \
                      sed 's/fleet_key_pair_name/key_pair_name/g'
                    )

# add new block at the end
if [ -n "$extracted_variables" ]; then
  echo "$(head -n -1 "$converted_file")
  runner_worker_docker_machine_fleet = {
    $extracted_variables
  }
  " > x && mv x "$converted_file"
fi

# rename the subnet_id_runners variable
sed -i 's/subnet_id_runners/subnet_id/g' "$converted_file"

# remove the \" from the autoscaling periods. No longer needed as jsonencode(value) is used
sed -i '/periods/s/\\"//g' "$converted_file"

# change the module source to cattle-ops
sed -i 's/npalm/cattle-ops/g' "$converted_file"

cat <<EOT
Not all cases are handled by this script. Please check the output file and make sure that all variables are converted correctly.
Take some time and sort the variables again for better readability.

Known issues:
  - commented lines are not supported. Remove them.
  - variable definitions with multiple lines are not supported. Rework manually.
  - `subnet_id` was taken from `subnet_id_runners`. Make sure that this is correct.
EOT

echo
echo "Module call converted. Output: $converted_file"


extracted_variables=$(grep -E '(runner_max_instance_lifetime_seconds|runner_enable_eip|runner_collect_autoscaling_metrics|runner_enable_monitoring|runner_gitlab_runner_name|runner_enable_ssm_access|runner_use_private_address|runner_root_block_device|runner_ebs_optimized|runner_spot_price|runner_instance_prefix|runner_instance_type|runner_extra_instance_tags)' "$1")

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

echo $extracted_variables

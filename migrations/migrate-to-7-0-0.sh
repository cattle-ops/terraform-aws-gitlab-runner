#!/bin/sh
set -eu

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
sed -i '/subnet_id_runners/d' "$converted_file"
sed -i '/subnet_ids_gitlab_runner/d' "$converted_file"
sed -i '/asg_terminate_lifecycle_hook_create/d' "$converted_file"
sed -i '/asg_terminate_lifecycle_hook_heartbeat_timeout/d' "$converted_file"
sed -i '/asg_terminate_lifecycle_lambda_memory_size/d' "$converted_file"
sed -i '/asg_terminate_lifecycle_lambda_runtime/d' "$converted_file"
sed -i '/asg_terminate_lifecycle_lambda_timeout/d' "$converted_file"

#
# PT #757 refactor!: rename variables and prefix with agent, executor and global scope
#
sed -i '/aws_region/d' "$converted_file"

sed 's/enable_kms/enable_managed_kms_key/g' "$converted_file" | \
sed 's/kms_alias_name/kms_managed_alias_name/g' | \
sed 's/kms_deletion_window_in_days/kms_managed_deletion_rotation_window_in_days/g' | \
sed 's/permission_boundary/iam_permission_boundary/g' | \
sed 's///g' | \
sed 's///g' | \
sed 's///g' | \
sed 's///g' | \
sed 's///g' | \
sed 's///g' | \
sed 's///g' | \
sed 's///g' | \
> "$converted_file.tmp" && mv "$converted_file.tmp" "$converted_file"

# overrides block
extracted_variables=$(grep -E '(name_sg|name_iam_objects|name_runner_agent_instance|name_docker_machine_runners)' "$converted_file")

extracted_variables=$(echo "$extracted_variables" | \
                      sed 's/name_sg/security_group_prefix/g' | \
                      sed 's/name_iam_objects/iam_object_prefix/g' | \
                      sed 's/name_runner_agent_instance/agent_instance_prefix/g' | \
                      sed 's/name_docker_machine_runners/executor_docker_machine_instance_prefix/g'
                    )

sed '/name_sg/d' "$converted_file" | \
sed '/name_iam_objects/d' | \
sed '/name_runner_agent_instance/d' | \
sed '/name_docker_machine_runners/d' | \
sed '/overrides = {/d' \
> "$converted_file.tmp" && mv "$converted_file.tmp" "$converted_file"

echo "$(head -n -1 "$converted_file")
  $extracted_variables
}" > "$converted_file.tmp" && mv "$converted_file.tmp" "$converted_file"

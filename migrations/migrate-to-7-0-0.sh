#!/bin/sh

set -eu

#
# Precondition: The module call has been extracted to a separate file given in "$1". The code is well-formatted.
#
# $1: file name containing the module call to be converted
#

converted_file="$1.new"

cp "$1" "$converted_file"

#
# PR #710 chore!: remove old variable `runners_pull_policy`
#
sed -i '/runners_pull_policy/d' "$converted_file"

#
# PR #511 feat!: allow to set all docker options for the Executor
#
extracted_variables=$(grep -E '(runners_docker_runtime|runners_helper_image|runners_shm_size|runners_shm_size|runners_extra_hosts|runners_disable_cache|runners_image|runners_privileged)' "$converted_file")

sed -i '/runners_image/d' "$converted_file"
sed -i '/runners_privileged/d' "$converted_file"
sed -i '/runners_disable_cache/d' "$converted_file"
sed -i '/runners_extra_hosts/d' "$converted_file"
sed -i '/runners_shm_size/d' "$converted_file"
sed -i '/runners_docker_runtime/d' "$converted_file"
sed -i '/runners_helper_image/d' "$converted_file"

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
                      sed 's/runners_helper_image/helper_image/g'
                    )

# add new block runners_docker_options at the end
echo "$(head -n -1 "$converted_file")
runners_docker_options {
  $extracted_variables
}
}" > x

mv x "$converted_file"

echo "Module call converted. Output: $converted_file"

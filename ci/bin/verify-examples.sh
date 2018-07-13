#!/usr/bin/env bash
TERRAFORM_VERSION=$1
DIR=$2

source $(dirname "${BASH_SOURCE[0]}")/terraform.sh
installTerraform

EXAMPLES="$(find ${DIR} -type d -mindepth 1 2> /dev/null )"
if [[ -z $EXAMPLES || "$($(echo $EXAMPLES) | wc -l)" -gt 0  ]] ; then
  echo "No example(s) directories found."
  exit 1
fi

for example in ${EXAMPLES} ; do
  echo Verifying example $example
  if [[ $(find ${example} -type f | grep "*.tf" | wc -l) -gt 0 ]] ; then
    echo no tf files
    exit 1
  fi
  validate ${example}
  verifyModulesAndPlugins ${example}
done

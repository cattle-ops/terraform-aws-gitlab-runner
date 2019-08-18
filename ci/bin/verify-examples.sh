#!/usr/bin/env bash
DIR=${1:-examples}
_PWD=$PWD

source $(dirname $0)/terraform.sh

EXAMPLES="$(find ${DIR} -maxdepth 1 -mindepth 1 -type d 2> /dev/null )"
echo $EXAMPLES
if [[ -z $EXAMPLES || $( echo $EXAMPLES | wc -l )  -eq 0  ]] ; then
  echo "No example(s) directories found."
  exit 1
fi

for example in ${EXAMPLES} ; do
  echo Verifying example $example
  if [[ $(find ${example} -type f | grep "*.tf" | wc -l) -gt 0 ]] ; then
    echo no tf files
    exit 1
  fi
  cd ${example}
  verifyModulesAndPlugins ${example}
  formatCheck ${example}
  validate ${example}
  cd $_PWD
done

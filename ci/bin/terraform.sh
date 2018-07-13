#!/usr/bin/env bash

OS=${TRAVIS_OS_NAME}
TARGET_DIR=/opt
TERRAFORM_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_${OS}_amd64.zip"

installTerraform() {
  echo "Downloading terraform: ${TERRAFORM_URL}"

  curl '-#' -fL -o ${TARGET_DIR}/terraform.zip ${TERRAFORM_URL} && \
    unzip -q -d ${TARGET_DIR}/ ${TARGET_DIR}/terraform.zip && \

  export PATH=${PATH}:${TARGET_DIR}

  terraform --version
}

verifyModulesAndPlugins() {
  echo "Verify plugins and modules can be resolved in $PWD"
  terraform init -get -backend=false -input=false
}

formatCheck() {
  RESULT=$(terraform fmt -write=false)
  if [[ ! -z ${RESULT} ]] ; then
    echo The following files are formatted incorrectly: $RESULT
    exit 1
  fi
}

validate() {
  echo "Validating and checking format of terraform code in $PWD"
  terraform validate -check-variables=false
  formatCheck
}

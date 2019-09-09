#!/usr/bin/env bash

TARGET_DIR=/opt
PATH=${PATH}:${TARGET_DIR}

TERRAFORM_VERSION=${1:-"0.12.8"}
OS=${2:-"linux"}
TERRAFORM_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_${OS}_amd64.zip"

installTerraform() {
  echo "Downloading terraform: ${TERRAFORM_URL}"

  curl '-#' -fL -o ${TARGET_DIR}/terraform.zip ${TERRAFORM_URL} && \
    unzip -q -d ${TARGET_DIR}/ ${TARGET_DIR}/terraform.zip && \

  terraform --version
}

verifyModulesAndPlugins() {
  echo "Verify plugins and modules can be resolved in $PWD"
  terraform init -get -backend=false -input=false
}

formatCheck() {
  RESULT=$(terraform fmt -recursive -write=false)
  if [[ ! -z ${RESULT} ]] ; then
    echo The following files are formatted incorrectly: $RESULT
    exit 1
  fi
}

validate() {
  echo "Validating and checking format of terraform code in $PWD"
  terraform validate
}


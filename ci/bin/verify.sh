#!/usr/bin/env bash
TERRAFORM_VERSION=$1

source $(dirname "${BASH_SOURCE[0]}")/terraform.sh

installTerraform
validate
verifyModulesAndPlugins

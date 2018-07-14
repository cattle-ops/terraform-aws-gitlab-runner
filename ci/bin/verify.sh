#!/usr/bin/env sh

source $(dirname $0)/terraform.sh

validate
verifyModulesAndPlugins

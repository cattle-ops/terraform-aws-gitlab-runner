#!/usr/bin/env bash

source $(dirname $0)/terraform.sh

validate
verifyModulesAndPlugins

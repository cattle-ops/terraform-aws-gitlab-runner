#!/usr/bin/env sh
set -e

packer build -force docker-machine.json

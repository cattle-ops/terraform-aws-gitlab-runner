#!/usr/bin/env bash

docker run --entrypoint="/bin/sh" -it --rm -w /build -v $(pwd):/build hashicorp/terraform:0.12.3 ./ci/bin/verify.sh
docker run --entrypoint="/bin/sh" -it --rm -w /build -v $(pwd):/build hashicorp/terraform:0.12.3 ./ci/bin/verify-examples.sh

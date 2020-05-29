#!/usr/bin/env sh
set -e

TOKEN=$(aws ssm get-parameters --name $3 --with-decryption --region $1 | jq -r ".Parameters | .[0] | .Value")
curl -sS --request DELETE "${2}/api/v4/runners" --form "token=${TOKEN}"
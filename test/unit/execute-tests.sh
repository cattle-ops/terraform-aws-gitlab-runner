#!/usr/bin/env bash

if [ ! -d "builds" ]; then
    mkdir builds || exit 3
fi

cp -dpr terraform/* builds/

(
  cd builds/ || exit 2

  # iterate over all test files
  for plan_file in plans/*.tf; do
      # complete the Terraform
      cp "${plan_file}" .

      # get the filename without the extension
      plan_name=$(basename "$plan_file")
      plan_name="${plan_name%.*}"

      terraform init
      terraform plan -var "environment=ut-${plan_name}" -out=output.tfplan
      terraform show -no-color -json output.tfplan > output.tfplan.json

      # copy the plan back
      cp output.tfplan.json "../terraform/plans/${plan_name}.tfplan.json"

      # clean up
      rm "${plan_name}.tf" output.tfplan output.tfplan.json
  done
)

# run the tests
go test -v
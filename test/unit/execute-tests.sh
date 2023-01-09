#!/usr/bin/env bash

mkdir builds/ || true

# iterate over all test files
for plan_file in plans/*.tf; do
  (
    # complete the Terraform
    cp "plans/${plan_file}" builds/
    cp "*.tf" "*.tfvars" builds/

    # build the plan
    cd builds/

    terraform init
    terraform plan -out=output.tfplan
    terraform show -no-color -json output.tfplan > output.tfplan.json

    # copy the plan back
    # get the filename without the extension
    plan_name=$(basename "$plan_file")
    plan_name="${plan_name%.*}"

    cp output.tfplan.json "../plans/${plan_name}.tfplan.json"

    # clean up
    rm "${plan_file}" output.tfplan output.tfplan.json
  )
done

# run the tests
go test -v -run UnitTestRunner
# Unit Tests

Unit tests operate on the Terraform plan in JSON format directly. No resources are created in the cloud.

## Terraform Setup

All tests share the files from the subdirectory `terraform/`. The files are copied into a build directory and one of the plan
files available at `terraform/plans/` is added. The workflow builds the plan and stores it next to the Terraform file in
`terraform/plans/`. The plan is named like the Terraform file but has the extension `plan`. This is done for every file in
`terraform/plans/`.

## The tests

Tests are based on a certain plan file and evaluate this plan. Sometimes Terraform does not know the exact value of a resource's
attribute. If this value is needed you have to write an integration test for it.
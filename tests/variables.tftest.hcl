run "setup_tests" {
  module {
    source = "./tests/modules/setup"
  }
}

run "create" {
  command = plan

  variables {
    vpc_id = run.setup_tests.vpc_id
    subnet_id = run.setup_tests.subnet_id
    environment = "test"
    runner_gitlab = {
      url = "https://my.fancy.url/not/used"
    }
  }

  assert {
    condition = output.runner_role_name == "runner"
    error_message = "Plan failed"
  }
}

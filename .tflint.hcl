plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "aws" {
    enabled = true
    version = "0.48.0"
    source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

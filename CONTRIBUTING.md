# Contribution guide

We appreciate your thought to contribute to open source. :heart: We want to make contributing as easy as possible. You are welcome to:

- Reporting a bug
- Discussing the current state of the code
- Submitting a fix
- Proposing new features

We Use [Github Flow](https://guides.github.com/introduction/flow/index.html), So All Code Changes Happen Through Pull Requests
Pull requests are the best way to propose changes to the codebase (we use [Github Flow](https://guides.github.com/introduction/flow/index.html)). We actively welcome your pull requests:

1. Fork the repo and create your branch from `develop`.
2. If you've added code, check one of the examples.
3. Make sure your code lints.
4. Raise a pull request.

## Terraform version

For development the terraform version is locked via [tfenv](https://github.com/tfutils/tfenv).

## Coding Style

We use the [Terraform Style conventions](https://www.terraform.io/docs/configuration/style.html). They are enforced with CI scripts.

## Documentation

We use [pre-commit](https://pre-commit.com/) to update the Terraform inputs and outputs in the documentation via [terraform-docs](https://github.com/terraform-docs/terraform-docs). Ensure you have installed those components.

## Testing

No automated tests are available. The example directory takes care of a few scenario's.

## License

By contributing, you agree that your contributions will be licensed under its MIT License.

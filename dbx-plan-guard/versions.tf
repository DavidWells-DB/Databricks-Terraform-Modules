terraform {
  # terraform_data requires Terraform >= 1.6 (the built-in terraform.io/builtin/terraform
  # provider). No external providers — this module is pure state-machine.
  required_version = ">= 1.6"
}

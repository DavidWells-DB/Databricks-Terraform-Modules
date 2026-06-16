# Integration tests — apply-command against a real AWS account.
#
# Credential-gated. Requires:
#   - AWS credentials (via env: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN, AWS_DEFAULT_REGION)
#
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# These tests verify:
#   1. The module actually creates the IGW, EIP, NAT Gateway, and routes in a real AWS account.
#   2. Outputs are non-empty and well-formed after apply.
#
# The plan-command tests in plan.tftest.hcl cover the static / mock-provider cases.
# This file covers the integration cases that require real cloud credentials.
#
# NOTE: This module is AWS-only and has no Databricks-side resources.
# The Minimum-tier (Premium) claim in the README refers to the Databricks workspace
# tier this networking supports; no tier-gated Databricks resource is created here,
# so the DATABRICKS_RULES.md Rule 4.1 tier-failure test case is not applicable.

provider "aws" {
  region = "us-east-1"
}

variables {
  nat_gateway_count = 1
  tags = {
    Test = "tftest-network-egress-internet"
  }
}

# Setup run block to create VPC and subnets
run "setup_vpc" {
  command = apply

  module {
    source = "./tests/fixtures/vpc"
  }
}

# Smoke test: module applies cleanly and produces non-empty outputs.
run "applies_and_produces_outputs" {
  command = apply

  variables {
    vpc_id                  = run.setup_vpc.vpc_id
    public_subnet_ids       = run.setup_vpc.public_subnet_ids
    private_route_table_ids = run.setup_vpc.private_route_table_ids
    nat_gateway_count       = 1
    tags                    = var.tags
  }

  assert {
    condition     = output.internet_gateway_id != ""
    error_message = "Expected non-empty internet_gateway_id after successful apply"
  }

  assert {
    condition     = startswith(output.internet_gateway_id, "igw-")
    error_message = "Expected internet_gateway_id to start with igw-"
  }

  assert {
    condition     = output.nat_gateway_id != ""
    error_message = "Expected non-empty nat_gateway_id after successful apply"
  }

  assert {
    condition     = startswith(output.nat_gateway_id, "nat-")
    error_message = "Expected nat_gateway_id to start with nat-"
  }

  assert {
    condition     = length(output.nat_gateway_ids) == 1
    error_message = "Expected exactly 1 NAT Gateway (nat_gateway_count = 1)"
  }

  assert {
    condition     = length(output.nat_public_ips) == 1
    error_message = "Expected exactly 1 NAT public IP"
  }

  assert {
    condition     = can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+$", output.nat_public_ip))
    error_message = "Expected nat_public_ip to be a valid IPv4 address"
  }

  assert {
    condition     = output.nat_gateway_id == output.nat_gateway_ids[0]
    error_message = "Expected nat_gateway_id convenience alias to match first entry in nat_gateway_ids"
  }

  assert {
    condition     = output.nat_public_ip == output.nat_public_ips[0]
    error_message = "Expected nat_public_ip convenience alias to match first entry in nat_public_ips"
  }
}

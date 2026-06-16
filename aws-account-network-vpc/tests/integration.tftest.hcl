# Integration tests — apply-command against real AWS + Databricks account.
#
# Credential-gated. Requires:
#   - AWS credentials with VPC/EC2 admin in the target account
#   - DATABRICKS_HOST, DATABRICKS_CLIENT_ID, DATABRICKS_CLIENT_SECRET, DATABRICKS_ACCOUNT_ID env vars
#
# Run with: terraform test -filter=tests/integration.tftest.hcl -var="databricks_account_id=${DATABRICKS_ACCOUNT_ID}"
#
# These tests verify:
#   1. The module actually creates the VPC, subnets, security group, and registers the network
#      configuration against a live Databricks account.
#   2. Tier-gated failure surfaces loudly (DATABRICKS_RULES.md Rule 4.1) — when applied against a
#      Standard-tier account, the API rejects and the apply fails clearly.
#
# The plan-command tests in plan.tftest.hcl cover the static / mock-provider cases. This file covers
# the integration cases that require real cloud credentials.

provider "aws" {
  region = "us-east-1"
}

provider "databricks" {
  alias      = "account"
  host       = "https://accounts.cloud.databricks.com"
  account_id = var.databricks_account_id
}

variable "databricks_account_id" {
  type = string
}

variables {
  databricks_gov_shard = null
  resource_prefix      = "tftest-aws-account-network-vpc"
  network_name         = "tftest-network"
  vpc_cidr             = "10.4.0.0/16"
  azs                  = ["us-east-1a", "us-east-1b"]
  private_subnet_cidrs = ["10.4.1.0/24", "10.4.2.0/24"]
  public_subnet_cidrs  = ["10.4.101.0/24", "10.4.102.0/24"]
  # databricks_account_id supplied via TF_VAR_databricks_account_id or .tfvars
}

# Smoke test: module applies cleanly against a Premium+ account and produces a usable network ID.
run "applies_against_premium_account" {
  command = apply

  assert {
    condition     = output.databricks_network_id != ""
    error_message = "Expected non-empty databricks_network_id after successful apply"
  }

  assert {
    condition     = output.vpc_id != ""
    error_message = "Expected non-empty vpc_id after successful apply"
  }

  assert {
    condition     = startswith(output.vpc_id, "vpc-")
    error_message = "Expected vpc_id to start with vpc- prefix"
  }

  assert {
    condition     = length(output.private_subnet_ids) == 2
    error_message = "Expected 2 private subnets after successful apply"
  }

  assert {
    condition     = length(output.public_subnet_ids) == 2
    error_message = "Expected 2 public subnets after successful apply"
  }

  assert {
    condition     = length(output.private_route_table_ids) == 2
    error_message = "Expected 2 private route tables after successful apply"
  }

  assert {
    condition     = output.security_group_id != ""
    error_message = "Expected non-empty security_group_id"
  }

  assert {
    condition     = startswith(output.security_group_id, "sg-")
    error_message = "Expected security_group_id to start with sg- prefix"
  }

  assert {
    condition     = output.vpc_cidr == "10.4.0.0/16"
    error_message = "Expected vpc_cidr to match input CIDR block"
  }

  assert {
    condition     = output.databricks_account_host == "https://accounts.cloud.databricks.com"
    error_message = "Expected databricks_account_host to be commercial endpoint when databricks_gov_shard is null"
  }
}

# Tier-gated failure test: against a Standard-tier account, expect failure.
# Per DATABRICKS_RULES.md Rule 2.3 + 4.1: this test is the empirical enforcement of the
# README's "Minimum tier: Premium" claim.
#
# Enable by overriding `databricks_account_id` to point at a Standard-tier account.
# Skipped until a Standard-tier test account is provisioned.
#
# run "fails_against_standard_tier_account" {
#   command = apply
#
#   variables {
#     databricks_account_id = "<standard-tier-account-id>"
#   }
#
#   expect_failures = [
#     databricks_mws_networks.this,
#   ]
# }

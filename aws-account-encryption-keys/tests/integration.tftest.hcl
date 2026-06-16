# Integration tests — apply-command against real AWS + Databricks account.
#
# Credential-gated. Requires:
#   - AWS credentials with KMS admin in the target account
#   - DATABRICKS_HOST, DATABRICKS_CLIENT_ID, DATABRICKS_CLIENT_SECRET, DATABRICKS_ACCOUNT_ID env vars
#
# Run with: terraform test -filter=tests/integration.tftest.hcl -var="databricks_account_id=${DATABRICKS_ACCOUNT_ID}"
#
# These tests verify:
#   1. The module actually creates the KMS keys and registers them as CMK configurations
#      against a live Databricks Premium account.
#   2. Tier-gated failure surfaces loudly (DATABRICKS_RULES.md Rule 4.1) — when applied against
#      a Standard-tier account, the API rejects and the apply fails clearly.
#
# The plan-command tests in plan.tftest.hcl cover the static / mock-provider cases. This file covers
# the integration cases that require real cloud credentials.

variable "databricks_account_id" {
  type = string
}

provider "aws" {
  region = "us-east-1"
}

provider "databricks" {
  alias      = "account"
  host       = "https://accounts.cloud.databricks.com"
  account_id = var.databricks_account_id
}

# Setup run: create prerequisite cross-account role
run "setup" {
  command = apply

  module {
    source = "./tests/fixtures/cross-account-role"
  }

  variables {
    databricks_account_id = var.databricks_account_id
  }
}

variables {
  aws_account_id              = run.setup.aws_account_id
  aws_partition               = "aws"
  databricks_gov_shard        = null
  cross_account_role_arn      = run.setup.cross_account_role_arn
  managed_services_key_alias  = "alias/tftest-databricks-managed-services"
  workspace_storage_key_alias = "alias/tftest-databricks-workspace-storage"
  tags = {
    Environment = "test"
    Purpose     = "integration-test"
  }
}

# Smoke test: module applies cleanly against a Premium+ account and produces usable CMK IDs.
run "applies_against_premium_account" {
  command = apply

  assert {
    condition     = output.managed_services_key_id != ""
    error_message = "Expected non-empty managed_services_key_id after successful apply"
  }

  assert {
    condition     = output.workspace_storage_key_id != ""
    error_message = "Expected non-empty workspace_storage_key_id after successful apply"
  }

  assert {
    condition     = startswith(output.managed_services_key_arn, "arn:aws:kms:")
    error_message = "Expected managed_services_key_arn to start with arn:aws:kms: for commercial partition"
  }

  assert {
    condition     = startswith(output.workspace_storage_key_arn, "arn:aws:kms:")
    error_message = "Expected workspace_storage_key_arn to start with arn:aws:kms: for commercial partition"
  }

  assert {
    condition     = output.managed_services_key_alias == "alias/tftest-databricks-managed-services"
    error_message = "Expected managed_services_key_alias to match input"
  }

  assert {
    condition     = output.workspace_storage_key_alias == "alias/tftest-databricks-workspace-storage"
    error_message = "Expected workspace_storage_key_alias to match input"
  }

  assert {
    condition     = output.databricks_control_plane_aws_account_id == "414351767826"
    error_message = "Expected commercial Databricks AWS account ID"
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
#     databricks_mws_customer_managed_keys.managed_services,
#   ]
# }

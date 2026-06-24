# Integration tests — apply-command against a real Databricks account.
#
# Credential-gated. Requires:
#   - Databricks account-level service principal (via env: DATABRICKS_CLIENT_ID, DATABRICKS_CLIENT_SECRET, DATABRICKS_ACCOUNT_ID)
#   - A Premium-tier (or above) Databricks account
#
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# These tests verify:
#   1. The module actually creates a serverless workspace against a live Databricks account.
#   2. Tier-gated failure surfaces loudly (DATABRICKS_RULES.md Rule 4.1) — when applied against a
#      Standard-tier account, the API rejects and the apply fails clearly.
#
# The plan-command tests in plan.tftest.hcl cover static / mock-provider cases.

provider "databricks" {
  alias      = "account"
  host       = "https://accounts.cloud.databricks.com"
  account_id = var.databricks_account_id
}

variables {
  workspace_name                 = "tftest-serverless-integ"
  region                         = "us-east-1"
  databricks_gov_shard           = null
  managed_services_key_id        = null
  network_connectivity_config_id = null
  deployment_name                = null
  custom_tags                    = {}
}

variable "databricks_account_id" {
  type = string
}

# Smoke test: module applies cleanly against a Premium+ account and produces a workspace_url.
run "applies_against_premium_account" {
  command = apply

  assert {
    condition     = output.workspace_id != ""
    error_message = "Expected non-empty workspace_id after successful apply"
  }

  assert {
    condition     = output.workspace_id != null
    error_message = "Expected workspace_id to be non-null"
  }

  assert {
    condition     = startswith(output.workspace_url, "https://")
    error_message = "Expected workspace_url to start with https://"
  }

  assert {
    condition     = output.workspace_host == output.workspace_url
    error_message = "Expected workspace_host to equal workspace_url"
  }

  assert {
    condition     = output.workspace_status == "RUNNING"
    error_message = "Expected workspace_status to be RUNNING after provisioning"
  }

  assert {
    condition     = output.databricks_account_host == "https://accounts.cloud.databricks.com"
    error_message = "Expected commercial account host for null databricks_gov_shard"
  }

  assert {
    condition     = output.ncc_binding_id == null
    error_message = "Expected ncc_binding_id to be null when no network_connectivity_config_id provided"
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
#     databricks_mws_workspaces.this,
#   ]
# }

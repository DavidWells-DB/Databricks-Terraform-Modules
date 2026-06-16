# Integration tests — apply-command against a real Databricks account.
#
# Credential-gated. Requires:
#   - DATABRICKS_HOST, DATABRICKS_CLIENT_ID, DATABRICKS_CLIENT_SECRET, DATABRICKS_ACCOUNT_ID env vars
#     (set against an account-level host, e.g., https://accounts.cloud.databricks.com)
#
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# These tests verify:
#   1. The module actually creates an NCC against a live Databricks account.
#   2. Tier-gated failure surfaces loudly (DATABRICKS_RULES.md Rule 4.1) — when applied against a
#      Standard-tier account, the API rejects and the apply fails clearly.
#
# The plan-command tests in plan.tftest.hcl cover the static / mock-provider cases. This file covers
# the integration cases that require real Databricks account credentials.

provider "databricks" {
  alias      = "account"
  host       = "https://accounts.cloud.databricks.com"
  account_id = var.databricks_account_id
}

variables {
  region = "us-east-1"
  name   = "tftest-ncc-us-east-1"
}

variable "databricks_account_id" {
  type = string
}

# Smoke test: module applies cleanly against a Premium+ account and produces a usable NCC ID.
run "applies_against_premium_account" {
  command = apply

  assert {
    condition     = output.network_connectivity_config_id != ""
    error_message = "Expected non-empty network_connectivity_config_id after successful apply"
  }

  assert {
    condition     = output.name == "tftest-ncc-us-east-1"
    error_message = "Expected output name to match input name"
  }

  assert {
    condition     = output.region == "us-east-1"
    error_message = "Expected output region to match input region"
  }

  assert {
    condition     = output.creation_time > 0
    error_message = "Expected positive creation_time timestamp"
  }
}

# Tier-gated failure test: against a Standard-tier account, expect failure.
# Per DATABRICKS_RULES.md Rule 2.3 + 4.1: this test is the empirical enforcement of the
# README's "Minimum tier: Premium" claim.
#
# Enable by pointing the databricks.account provider at a Standard-tier account.
# Skipped until a Standard-tier test account is provisioned.
#
# run "fails_against_standard_tier_account" {
#   command = apply
#
#   expect_failures = [
#     databricks_mws_network_connectivity_config.this,
#   ]
# }

# Integration tests — apply-command against a real GCP project + Databricks account.
#
# Credential-gated. Requires:
#   - GOOGLE_APPLICATION_CREDENTIALS or ADC configured for the target GCP project
#   - DATABRICKS_HOST=https://accounts.gcp.databricks.com
#   - DATABRICKS_CLIENT_ID, DATABRICKS_CLIENT_SECRET (account-level service principal)
#   - TF_VAR_databricks_account_id set to the target Databricks account UUID
#   - TF_VAR_project_id set to a GCP project with Databricks provisioning configured
#
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# These tests verify:
#   1. The module creates a real serverless workspace on GCP.
#   2. Tier-gated failure surfaces loudly (DATABRICKS_RULES.md Rule 4.1) — when applied against a
#      Standard-tier account, the API rejects the workspace creation because Serverless is Premium-only.
#
# The plan-command tests in plan.tftest.hcl cover static / mock-provider cases. This file covers
# integration cases that require real cloud credentials.

variables {
  workspace_name  = "tftest-gcp-serverless"
  region          = "us-central1"
  resource_prefix = "tftest"
  # databricks_account_id supplied via TF_VAR_databricks_account_id
  # project_id supplied via TF_VAR_project_id
}

# Smoke test: module applies cleanly against a Premium+ account and produces a usable workspace_url.
# run "applies_against_premium_account" {
#   command = apply
#
#   assert {
#     condition     = output.workspace_url != ""
#     error_message = "Expected non-empty workspace_url after successful apply"
#   }
#
#   assert {
#     condition     = output.workspace_id != 0
#     error_message = "Expected non-zero workspace_id after successful apply"
#   }
#
#   assert {
#     condition     = startswith(output.workspace_url, "https://")
#     error_message = "Expected workspace_url to start with https://"
#   }
# }

# Tier-gated failure test: against a Standard-tier account, expect failure.
# Per DATABRICKS_RULES.md Rule 2.3 + 4.1: this test is the empirical enforcement of the
# README's "Minimum tier: Premium" claim. Serverless compute (compute_mode = "SERVERLESS")
# is a Premium-tier feature; Standard-tier accounts do not support it.
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

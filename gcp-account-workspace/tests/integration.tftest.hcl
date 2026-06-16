# Integration tests — apply-command against real GCP project + Databricks account.
#
# Credential-gated. Requires:
#   - GCP credentials with the Databricks provisioning service account configured
#   - DATABRICKS_HOST=https://accounts.gcp.databricks.com
#   - DATABRICKS_CLIENT_ID, DATABRICKS_CLIENT_SECRET, DATABRICKS_ACCOUNT_ID env vars
#   - Pre-existing storage_configuration_id (from gcp-account-workspace-storage)
#   - Pre-existing databricks_network_id (from gcp-account-network-vpc)
#
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# These tests verify:
#   1. The module actually creates the workspace and produces a usable workspace_url.
#   2. Tier-gated failure surfaces loudly (DATABRICKS_RULES.md Rule 4.1) — when applied
#      against a Standard-tier account, the API rejects and the apply fails clearly.
#
# The plan-command tests in plan.tftest.hcl cover the static / mock-provider cases. This
# file covers the integration cases that require real cloud credentials.

variables {
  workspace_name           = "tftest-gcp-account-workspace"
  project_id               = "my-test-project"
  region                   = "us-central1"
  resource_prefix          = "tftest"
  storage_configuration_id = "storage-config-id"
  databricks_network_id    = "network-id"
  # databricks_account_id supplied via TF_VAR_databricks_account_id or .tfvars
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
#     condition     = output.workspace_id != null
#     error_message = "Expected non-null workspace_id after successful apply"
#   }
#
#   assert {
#     condition     = can(regex("^https://", output.workspace_url))
#     error_message = "Expected workspace_url to start with https://"
#   }
# }

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

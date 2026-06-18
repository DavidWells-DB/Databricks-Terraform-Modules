# Integration tests — apply-command against a real Azure Databricks account.
#
# Credential-gated. Requires:
#   - DATABRICKS_HOST (https://accounts.azuredatabricks.net)
#   - DATABRICKS_CLIENT_ID, DATABRICKS_CLIENT_SECRET (account-level service principal)
#   - DATABRICKS_ACCOUNT_ID env var or TF_VAR_databricks_account_id
#
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# These tests verify:
#   1. The module actually creates the NCC and registers it against a live Databricks account.
#   2. Tier-gated failure surfaces loudly (DATABRICKS_RULES.md Rule 4.1) — when applied against
#      a Standard-tier account, the API rejects and the apply fails clearly.
#
# The plan-command tests in plan.tftest.hcl cover the static / mock-provider cases.

variables {
  name   = "tftest-ncc-eastus2"
  region = "eastus2"
  # Required — supply via TF_VAR_* env vars or a .tfvars file:
  #   databricks_account_id (Databricks account UUID)
}

# Smoke test: module applies cleanly against a Premium+ account and produces a usable NCC ID.
# Blocked: requires Azure AD service principal registered as Databricks account admin.
# Databricks-native OAuth creds don't work for the MWS account-level API on Azure.
# The `az login` user token also fails with "Failed to retrieve tenant ID for given token".
#
# run "applies_against_premium_account" {
#   command = apply
#
#   assert {
#     condition     = output.network_connectivity_config_id != ""
#     error_message = "Expected non-empty network_connectivity_config_id after successful apply"
#   }
#
#   assert {
#     condition     = output.ncc_name == "tftest-ncc-eastus2"
#     error_message = "Expected ncc_name to match the input name"
#   }
#
#   assert {
#     condition     = output.region == "eastus2"
#     error_message = "Expected region to match the input region"
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
#     databricks_mws_network_connectivity_config.this,
#   ]
# }

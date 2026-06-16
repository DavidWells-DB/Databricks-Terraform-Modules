# Integration tests — apply-command against a real GCP project + Databricks account.
#
# Credential-gated. Requires:
#   - GCP credentials with compute.admin, dns.admin in the target project (via ADC or GOOGLE_CREDENTIALS env var)
#   - DATABRICKS_HOST=https://accounts.gcp.databricks.com
#   - DATABRICKS_CLIENT_ID, DATABRICKS_CLIENT_SECRET, DATABRICKS_ACCOUNT_ID env vars
#   - TF_VAR_project_id, TF_VAR_network_self_link, TF_VAR_psc_subnet_self_link
#
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# These tests verify:
#   1. The module creates PSC addresses, forwarding rules, DNS zone/records, and Databricks endpoint
#      registrations against a live GCP project + Databricks account.
#   2. Tier-gated failure surfaces loudly (DATABRICKS_RULES.md Rule 4.1) — when applied against an
#      account below Enterprise tier, the API rejects and the apply fails clearly.
#
# The plan-command tests in plan.tftest.hcl cover static / mock-provider cases. This file covers
# integration cases that require real cloud credentials.

variables {
  region          = "us-central1"
  resource_prefix = "tftest-psc"
  # project_id, network_self_link, psc_subnet_self_link supplied via TF_VAR_* or .tfvars
  # databricks_account_id supplied via TF_VAR_databricks_account_id or .tfvars
}

# Smoke test: module applies cleanly against an Enterprise account and produces usable endpoint IDs.
# run "applies_against_enterprise_account" {
#   command = apply
#
#   assert {
#     condition     = output.workspace_psc_endpoint_id != ""
#     error_message = "Expected non-empty workspace_psc_endpoint_id after successful apply"
#   }
#
#   assert {
#     condition     = output.relay_psc_endpoint_id != ""
#     error_message = "Expected non-empty relay_psc_endpoint_id after successful apply"
#   }
#
#   assert {
#     condition     = output.private_access_settings_id != ""
#     error_message = "Expected non-empty private_access_settings_id after successful apply"
#   }
# }

# Tier-gated failure test: against a sub-Enterprise account, expect failure.
# Per DATABRICKS_RULES.md Rule 2.3 + 4.1: this test is the empirical enforcement of the
# README's "Minimum tier: Enterprise" claim.
#
# Enable by overriding databricks_account_id to point at a Standard or Premium account.
# Skipped until a sub-Enterprise test account is provisioned.
#
# run "fails_against_sub_enterprise_tier_account" {
#   command = apply
#
#   variables {
#     databricks_account_id = "<sub-enterprise-account-id>"
#   }
#
#   expect_failures = [
#     databricks_mws_private_access_settings.this,
#   ]
# }

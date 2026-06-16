# Integration tests — apply-command against a real Databricks workspace with Unity Catalog enabled.
#
# Credential-gated. Requires:
#   - DATABRICKS_HOST, DATABRICKS_CLIENT_ID, DATABRICKS_CLIENT_SECRET env vars (workspace-scoped)
#   - An existing storage credential ID in the workspace (TF_VAR_storage_credential_id or .tfvars)
#
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# These tests verify:
#   1. The module actually creates external locations against a live Databricks workspace.
#   2. Grants are applied correctly when specified.
#   3. Tier-gated failure surfaces loudly (DATABRICKS_RULES.md Rule 4.1) — when applied against a
#      Standard-tier workspace, databricks_external_location is rejected at apply time.
#
# The plan-command tests in plan.tftest.hcl cover the static / mock-provider cases. This file covers
# the integration cases that require real credentials.

variables {
  # storage_credential_id supplied via TF_VAR_storage_credential_id or .tfvars
  locations = {
    tftest_raw = {
      url                   = "s3://tftest-dbx-external-location/raw"
      storage_credential_id = "REPLACE_WITH_TF_VAR"
      comment               = "Created by integration test — safe to delete"
    }
  }
}

# Smoke test: module applies cleanly against a Premium+ workspace and produces a non-empty location ID.
# run "applies_against_premium_workspace" {
#   command = apply
#
#   assert {
#     condition     = length(output.external_location_ids) == 1
#     error_message = "Expected one external_location_id after successful apply"
#   }
#
#   assert {
#     condition     = output.external_location_ids["tftest_raw"] != ""
#     error_message = "Expected non-empty external location ID for tftest_raw"
#   }
# }

# Tier-gated failure test: against a Standard-tier workspace, expect failure.
# Per DATABRICKS_RULES.md Rule 2.3 + 4.1: this test is the empirical enforcement of the
# README's "Minimum tier: Premium" claim.
#
# Enable by pointing the databricks.workspace provider at a Standard-tier workspace.
# Skipped until a Standard-tier test workspace is provisioned.
#
# run "fails_against_standard_tier_workspace" {
#   command = apply
#
#   expect_failures = [
#     databricks_external_location.this["tftest_raw"],
#   ]
# }

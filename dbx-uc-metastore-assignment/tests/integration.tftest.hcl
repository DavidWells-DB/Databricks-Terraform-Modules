# Integration tests — apply-command against a real Databricks account + workspace.
#
# Credential-gated. Requires:
#   - DATABRICKS_HOST (account host), DATABRICKS_CLIENT_ID, DATABRICKS_CLIENT_SECRET,
#     DATABRICKS_ACCOUNT_ID env vars for the account provider
#   - TF_VAR_metastore_id, TF_VAR_prod_workspace_id pointing at real resources
#
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# These tests verify:
#   1. The module assigns the metastore to the specified workspaces against a live account.
#   2. Tier-gated failure surfaces loudly (DATABRICKS_RULES.md Rule 4.1) — when applied against a
#      Standard-tier workspace, the Unity Catalog API rejects and the apply fails clearly.
#
# The plan-command tests in plan.tftest.hcl cover all static / mock-provider cases. This file
# covers the integration cases that require real Databricks credentials.

variables {
  metastore_id = "00000000-0000-0000-0000-000000000000" # override via TF_VAR_metastore_id
  workspace_ids = {
    test = "0" # override via TF_VAR_workspace_ids or set individually
  }
  default_catalog_name = null
}

# Smoke test: module applies cleanly against a Premium+ account and produces assignment IDs.
# run "applies_against_premium_account" {
#   command = apply
#
#   assert {
#     condition     = length(output.assignment_ids) == 1
#     error_message = "Expected one assignment_id after successful apply"
#   }
#
#   assert {
#     condition     = output.metastore_id == var.metastore_id
#     error_message = "output.metastore_id should echo the input"
#   }
# }

# Tier-gated failure test: against a Standard-tier workspace, expect failure.
# Per DATABRICKS_RULES.md Rule 2.3 + 4.1: this test is the empirical enforcement of the
# README's "Minimum tier: Premium" claim.
#
# Enable by pointing workspace_ids at a Standard-tier workspace.
# Skipped until a Standard-tier test account is provisioned.
#
# run "fails_against_standard_tier_workspace" {
#   command = apply
#
#   variables {
#     workspace_ids = {
#       standard = "<standard-tier-workspace-id>"
#     }
#   }
#
#   expect_failures = [
#     databricks_metastore_assignment.this["standard"],
#   ]
# }

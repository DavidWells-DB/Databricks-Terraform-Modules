# Integration tests — apply-command against a real Databricks account.
#
# Credential-gated. Requires:
#   - DATABRICKS_HOST, DATABRICKS_CLIENT_ID, DATABRICKS_CLIENT_SECRET, DATABRICKS_ACCOUNT_ID env vars
#     (or equivalent provider configuration at the root)
#   - A Premium+ Databricks account with at least one workspace and one account-level group.
#
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# These tests verify:
#   1. The module actually creates permission assignments against a live Databricks account.
#   2. Tier-gated failure surfaces loudly (DATABRICKS_RULES.md Rule 4.1) — when applied against
#      a Standard-tier account, the API rejects and the apply fails clearly.
#
# The plan-command tests in plan.tftest.hcl cover static / mock-provider cases. This file covers
# integration cases that require real cloud credentials.

variables {
  # workspace_id supplied via TF_VAR_workspace_id or .tfvars
  # assignments supplied via TF_VAR_assignments or .tfvars
}

# Smoke test: module applies cleanly against a Premium+ account and produces non-empty assignment IDs.
# run "applies_against_premium_account" {
#   command = apply
#
#   variables {
#     workspace_id = "<premium-workspace-id>"
#     assignments = {
#       test_group = {
#         principal_id = <account-group-principal-id>
#         roles        = ["USER"]
#       }
#     }
#   }
#
#   assert {
#     condition     = length(output.assignment_ids) > 0
#     error_message = "Expected non-empty assignment_ids after successful apply"
#   }
#
#   assert {
#     condition     = output.assignment_ids["test_group"] != ""
#     error_message = "Expected non-empty assignment ID for test_group"
#   }
# }

# Tier-gated failure test: against a Standard-tier account, expect failure.
# Per DATABRICKS_RULES.md Rule 2.3 + 4.1: this test is the empirical enforcement of the
# README's "Minimum tier: Premium" claim.
#
# Enable by pointing workspace_id at a Standard-tier workspace.
# Skipped until a Standard-tier test workspace is provisioned.
#
# run "fails_against_standard_tier_workspace" {
#   command = apply
#
#   variables {
#     workspace_id = "<standard-tier-workspace-id>"
#     assignments = {
#       test_group = {
#         principal_id = <account-group-principal-id>
#         roles        = ["USER"]
#       }
#     }
#   }
#
#   expect_failures = [
#     databricks_mws_permission_assignment.this["test_group"],
#   ]
# }

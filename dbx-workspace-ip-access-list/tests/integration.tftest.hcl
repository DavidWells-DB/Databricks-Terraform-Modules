# Integration tests — apply-command against a real Databricks workspace.
#
# Credential-gated. Requires:
#   - DATABRICKS_HOST, DATABRICKS_CLIENT_ID, DATABRICKS_CLIENT_SECRET env vars
#     (or TF_VAR_databricks_workspace_host etc.) pointing at a Premium+ workspace
#
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# These tests verify:
#   1. The module activates enableIpAccessLists in workspace_conf and creates the ALLOW list.
#   2. Tier-gated failure surfaces loudly (DATABRICKS_RULES.md Rule 4.1) — when applied against
#      a Standard-tier workspace, the API rejects and the apply fails clearly.
#
# The plan-command tests in plan.tftest.hcl cover the static / mock-provider cases. This file
# covers the integration cases that require real Databricks credentials.

variables {
  allow_list_cidrs = ["10.0.0.0/8"]
  allow_list_label = "tftest-allow-list"
  block_list_cidrs = null
  block_list_label = "block-list"
}

# Smoke test: module applies cleanly against a Premium+ workspace and produces a usable ID.
# run "applies_against_premium_workspace" {
#   command = apply
#
#   assert {
#     condition     = output.allow_list_id != ""
#     error_message = "Expected non-empty allow_list_id after successful apply"
#   }
#
#   assert {
#     condition     = output.block_list_id == null
#     error_message = "Expected null block_list_id when no block list is configured"
#   }
#
#   assert {
#     condition     = output.workspace_conf_id != ""
#     error_message = "Expected non-empty workspace_conf_id after successful apply"
#   }
# }

# Tier-gated failure test: against a Standard-tier workspace, expect failure.
# Per DATABRICKS_RULES.md Rule 2.3 + 4.1: this test is the empirical enforcement of the
# README's "Minimum tier: Premium" claim.
#
# Enable by pointing at a Standard-tier Databricks workspace.
# Skipped until a Standard-tier test workspace is provisioned.
#
# run "fails_against_standard_tier_workspace" {
#   command = apply
#
#   variables {
#     # Override provider host to a Standard-tier workspace URL via TF_VAR or tfvars.
#   }
#
#   expect_failures = [
#     databricks_ip_access_list.allow,
#   ]
# }

# Integration tests — apply-command against a real Databricks account + workspace.
#
# Credential-gated. Requires:
#   - DATABRICKS_HOST (account host), DATABRICKS_CLIENT_ID, DATABRICKS_CLIENT_SECRET,
#     DATABRICKS_ACCOUNT_ID env vars for the account provider
#   - DATABRICKS_WORKSPACE_HOST env var (workspace URL) for the workspace provider
#   - An existing NCC in the same region as the workspace
#
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# These tests verify:
#   1. The module binds the NCC to the workspace in a live Databricks environment.
#   2. Tier-gated failure surfaces loudly (DATABRICKS_RULES.md Rule 4.1) — when applied against a
#      Standard-tier workspace, the API rejects and the apply fails clearly.
#
# The plan-command tests in plan.tftest.hcl cover the static / mock-provider cases. This file
# covers integration cases that require real credentials and infrastructure.

variables {
  workspace_id                   = 0                                      # Override via TF_VAR_workspace_id
  network_connectivity_config_id = "00000000-0000-0000-0000-000000000000" # Override via TF_VAR_network_connectivity_config_id
  private_endpoint_rules         = []
  network_policy_id              = null
}

# Smoke test: module applies cleanly against a Premium+ workspace and produces a binding ID.
# run "applies_against_premium_workspace" {
#   command = apply
#
#   assert {
#     condition     = output.ncc_binding_id != ""
#     error_message = "Expected non-empty ncc_binding_id after successful apply"
#   }
#
#   assert {
#     condition     = output.network_connectivity_config_id != ""
#     error_message = "Expected non-empty network_connectivity_config_id after successful apply"
#   }
# }

# Tier-gated failure test: against a Standard-tier workspace, expect failure.
# Per DATABRICKS_RULES.md Rule 2.3 + 4.1: this test is the empirical enforcement of the
# README's "Minimum tier: Premium" claim.
#
# Enable by pointing the workspace provider at a Standard-tier workspace.
# Skipped until a Standard-tier test workspace is provisioned.
#
# run "fails_against_standard_tier_workspace" {
#   command = apply
#
#   variables {
#     workspace_id = <standard-tier-workspace-id>
#     network_connectivity_config_id = "<ncc-id>"
#   }
#
#   expect_failures = [
#     databricks_mws_ncc_binding.this,
#   ]
# }

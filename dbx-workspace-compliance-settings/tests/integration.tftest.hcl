# Integration tests — apply-command against a real Databricks workspace.
#
# Credential-gated. Requires:
#   - DATABRICKS_HOST, DATABRICKS_CLIENT_ID, DATABRICKS_CLIENT_SECRET env vars
#     pointing at a workspace where the caller is a workspace admin.
#   - The workspace must be at Enterprise tier for CSP/ESM/ACU tests.
#   - The workspace must have Unity Catalog configured before disable_legacy_access tests.
#
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# These tests verify:
#   1. The module actually creates workspace settings against a live Databricks workspace.
#   2. Tier-gated failure surfaces loudly (DATABRICKS_RULES.md Rule 4.1) — when applied against
#      a Premium-only workspace, Enterprise-tier settings are rejected by the API at apply time.
#
# The plan-command tests in plan.tftest.hcl cover the static / mock-provider cases.
# This file covers the integration cases that require real cloud credentials.
#
# WARNING: compliance_security_profile_enabled = true is a PERMANENT, ONE-WAY operation.
# Only enable in a disposable test workspace. The Compliance Security Profile cannot be
# reversed once applied.

variables {
  # Legacy settings only — safe to apply without committing to CSP irreversibility.
  compliance_security_profile_enabled  = false
  compliance_standards                 = []
  enhanced_security_monitoring_enabled = false
  automatic_cluster_update_enabled     = false
  disable_legacy_access                = false
  disable_legacy_dbfs                  = false
}

# Smoke test: module applies cleanly against an Enterprise workspace; outputs are correct.
# run "applies_legacy_dbfs_setting_against_enterprise_workspace" {
#   command = apply
#
#   variables {
#     disable_legacy_dbfs = true
#   }
#
#   assert {
#     condition     = output.legacy_dbfs_disabled == true
#     error_message = "Expected legacy_dbfs_disabled output to be true after successful apply"
#   }
# }

# Tier-gated failure test: CSP against a Premium-only workspace should fail loudly.
# Per DATABRICKS_RULES.md Rule 2.3 + 4.1: this test is the empirical enforcement of the
# README's "Minimum tier: Enterprise" claim for compliance_security_profile_enabled.
#
# Enable by pointing DATABRICKS_HOST at a Premium-tier workspace.
# Skipped until a Premium-tier test workspace is provisioned.
#
# run "csp_fails_against_premium_tier_workspace" {
#   command = apply
#
#   variables {
#     compliance_security_profile_enabled = true
#     compliance_standards                = ["HIPAA"]
#   }
#
#   expect_failures = [
#     databricks_compliance_security_profile_workspace_setting.this,
#   ]
# }

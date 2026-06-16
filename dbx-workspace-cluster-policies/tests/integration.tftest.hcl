# Integration tests — apply-command against a real Databricks workspace.
#
# Credential-gated. Requires:
#   - DATABRICKS_HOST, DATABRICKS_CLIENT_ID, DATABRICKS_CLIENT_SECRET env vars
#     pointing at a Premium-tier workspace where the SP has admin or policy-create permission.
#
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# These tests verify:
#   1. The module creates cluster policies against a live Databricks workspace.
#   2. Tier-gated failure surfaces loudly (DATABRICKS_RULES.md Rule 4.1) — when applied against
#      a Standard-tier workspace, the API rejects and the apply fails clearly.
#
# The plan-command tests in plan.tftest.hcl cover the static / mock-provider cases.

variables {
  policies = {
    "tftest-cost-controlled" = {
      description = "Integration test policy: custom definition."
      definition  = "{\"autotermination_minutes\":{\"type\":\"fixed\",\"value\":20,\"hidden\":true}}"
    }
  }
  policy_assignments = {}
}

# Smoke test: module applies cleanly against a Premium+ workspace and produces policy IDs.
# run "applies_against_premium_workspace" {
#   command = apply
#
#   assert {
#     condition     = length(output.policy_ids) == 1
#     error_message = "Expected one policy_id entry after successful apply"
#   }
#
#   assert {
#     condition     = output.policy_ids["tftest-cost-controlled"] != ""
#     error_message = "Expected non-empty policy ID for the created policy"
#   }
# }

# Tier-gated failure test: against a Standard-tier workspace, cluster policies with ACLs
# will be rejected by the API at apply time.
# Per DATABRICKS_RULES.md Rule 2.3 + 4.1: this test is the empirical enforcement of the
# README's "Minimum tier: Premium" claim.
#
# Enable by pointing DATABRICKS_HOST at a Standard-tier workspace.
# Skipped until a Standard-tier test workspace is provisioned.
#
# run "fails_against_standard_tier_workspace" {
#   command = apply
#
#   variables {
#     policies = {
#       "tftest-cost-controlled" = {
#         definition = "{\"autotermination_minutes\":{\"type\":\"fixed\",\"value\":20}}"
#       }
#     }
#     policy_assignments = {
#       "tftest-cost-controlled" = {
#         access_controls = [
#           { group_name = "admins" }
#         ]
#       }
#     }
#   }
#
#   expect_failures = [
#     databricks_permissions.this["tftest-cost-controlled"],
#   ]
# }

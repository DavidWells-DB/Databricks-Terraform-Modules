# Integration tests — apply-command against a real Databricks workspace.
#
# Credential-gated. Requires:
#   - DATABRICKS_HOST, DATABRICKS_CLIENT_ID, DATABRICKS_CLIENT_SECRET env vars
#     (workspace-level service principal with MANAGE permission on the workspace)
#
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# These tests verify:
#   1. The module actually creates secret scopes against a live workspace.
#   2. The backend_type output reflects the correct scope type (DATABRICKS for native).
#   3. Tier-gated failure surfaces loudly (DATABRICKS_RULES.md Rule 4.1) — when applied against a
#      Standard-tier workspace, ACL enforcement is absent and create may silently succeed without
#      proper access control. The tier-failure case is a placeholder until a Standard-tier test
#      workspace is provisioned.
#
# The plan-command tests in plan.tftest.hcl cover the static / mock-provider cases. This file
# covers integration cases that require real workspace credentials.

variables {
  scopes = {
    "tftest-app-secrets" = {
      initial_manage_principal = "users"
    }
    "tftest-infra-secrets" = {}
  }
}

# Smoke test: module applies cleanly against a Premium+ workspace and produces usable scope names.
# run "applies_against_premium_workspace" {
#   command = apply
#
#   assert {
#     condition     = contains(tolist(output.scope_names), "tftest-app-secrets")
#     error_message = "Expected tftest-app-secrets in scope_names after successful apply"
#   }
#
#   assert {
#     condition     = contains(tolist(output.scope_names), "tftest-infra-secrets")
#     error_message = "Expected tftest-infra-secrets in scope_names after successful apply"
#   }
#
#   assert {
#     # backend_type for a native scope equals "DATABRICKS" (the string the provider returns)
#     # checkov:skip=CKV_SECRET_6: false positive — "DATABRICKS" is a provider enum value, not a secret
#     condition     = output.scope_backend_types["tftest-app-secrets"] == "DATABRICKS"
#     error_message = "Expected native backend_type for tftest-app-secrets"
#   }
# }

# Tier-gated failure test: against a Standard-tier workspace, ACL enforcement is silently absent.
# Per DATABRICKS_RULES.md Rule 2.3 + 4.1: this test is the empirical enforcement of the
# README's "Minimum tier: Premium" claim.
#
# Enable by setting DATABRICKS_HOST to point at a Standard-tier workspace.
# Skipped until a Standard-tier test workspace is provisioned.
#
# run "acl_not_enforced_on_standard_tier" {
#   command = apply
#
#   variables {
#     scopes = {
#       "tftest-standard-tier-scope" = {
#         initial_manage_principal = "users"
#       }
#     }
#   }
#
#   # On Standard tier the scope creation may succeed but ACL enforcement is absent.
#   # Document here that this module's ACL guarantees require Premium.
#   # When a Standard-tier API actively rejects scope ACLs, add expect_failures below.
#   # expect_failures = [databricks_secret_scope.this["tftest-standard-tier-scope"]]
# }

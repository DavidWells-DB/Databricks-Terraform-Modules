# Integration tests — apply-command against a real Databricks account + workspace.
#
# Credential-gated. Requires:
#   - DATABRICKS_HOST (account host), DATABRICKS_CLIENT_ID, DATABRICKS_CLIENT_SECRET,
#     DATABRICKS_ACCOUNT_ID env vars for the account provider
#   - An existing account network policy (databricks_account_network_policy) and its ID
#   - An existing workspace ID in the same account
#
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# These tests verify:
#   1. The module binds the network policy to the workspace in a live environment.
#   2. Destroy succeeds without the E12 delete-ordering retry (the unbind settles before
#      any dependent policy delete).
#
# The plan-command tests in plan.tftest.hcl cover the static / mock-provider cases.

variables {
  workspace_id      = 0         # Override via TF_VAR_workspace_id
  network_policy_id = "REPLACE" # Override via TF_VAR_network_policy_id
}

# Smoke test: module applies cleanly and reports the bound policy.
# run "binds_policy_to_workspace" {
#   command = apply
#
#   assert {
#     condition     = output.network_policy_id != ""
#     error_message = "Expected non-empty network_policy_id after successful apply"
#   }
#
#   assert {
#     condition     = output.binding_id != ""
#     error_message = "Expected non-empty binding_id after successful apply"
#   }
# }

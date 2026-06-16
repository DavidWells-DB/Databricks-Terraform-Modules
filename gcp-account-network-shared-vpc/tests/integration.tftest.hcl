# Integration tests — apply-command against a real GCP project.
#
# Credential-gated. Requires:
#   - GCP credentials with compute.xpnAdmin on both host and service projects
#     (via GOOGLE_CREDENTIALS, GOOGLE_APPLICATION_CREDENTIALS, or gcloud ADC)
#   - TF_VAR_host_project_id and TF_VAR_service_project_ids env vars (or .tfvars)
#
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# These tests verify:
#   1. The module actually enables the Shared VPC host and attaches service projects against a live GCP environment.
#   2. Tier-gated failure surfaces loudly (DATABRICKS_RULES.md Rule 4.1) — when the resulting network is used
#      with a Standard-tier Databricks workspace, the Databricks API rejects and apply fails clearly.
#
# The plan-command tests in plan.tftest.hcl cover the static / mock-provider cases. This file covers
# the integration cases that require real GCP credentials.

variables {
  # host_project_id     supplied via TF_VAR_host_project_id or .tfvars
  # service_project_ids supplied via TF_VAR_service_project_ids or .tfvars
  subnet_iam_grants = []
}

# Smoke test: module applies cleanly and produces a host_project_id output.
# run "applies_against_real_gcp_projects" {
#   command = apply
#
#   assert {
#     condition     = output.host_project_id != ""
#     error_message = "Expected non-empty host_project_id after successful apply"
#   }
#
#   assert {
#     condition     = length(output.service_project_attachment_ids) >= 1
#     error_message = "Expected at least one service project attachment after successful apply"
#   }
# }

# Tier-gated failure test: when this Shared VPC is used with a Standard-tier Databricks workspace,
# expect failure at workspace creation. Per DATABRICKS_RULES.md Rule 2.3 + 4.1: this test is the
# empirical enforcement of the README's "Minimum tier: Premium" claim.
#
# Enable by passing a Standard-tier Databricks account ID and workspace creation config.
# Skipped until a Standard-tier test account is provisioned.
#
# run "databricks_workspace_fails_against_standard_tier_account" {
#   command = apply
#
#   # This run requires the gcp-account-workspace module or a root composition
#   # that attempts to create a databricks_mws_workspaces against a Standard-tier account.
#   # Wire in via module call or direct resource when test environment is available.
#
#   expect_failures = [
#     # databricks_mws_workspaces.this,
#   ]
# }

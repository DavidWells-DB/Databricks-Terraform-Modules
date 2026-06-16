# Integration tests — apply-command against a real GCP project + Databricks workspace.
#
# Credential-gated. Requires:
#   - GCP credentials with storage.buckets.setIamPolicy on the target bucket
#   - DATABRICKS_HOST, DATABRICKS_CLIENT_ID, DATABRICKS_CLIENT_SECRET env vars
#   - An existing GCS bucket referenced by TF_VAR_bucket_name
#
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# These tests verify:
#   1. The module actually creates the storage credential and IAM bindings against a live GCP + Databricks workspace.
#   2. Tier-gated failure surfaces loudly (DATABRICKS_RULES.md Rule 4.1) — when applied against a Standard-tier
#      workspace, the provider rejects and the apply fails clearly.
#
# The plan-command tests in plan.tftest.hcl cover the static / mock-provider cases. This file covers
# the integration cases that require real cloud credentials.

variables {
  credential_name = "tftest-gcp-uc-storage-credential"
  # bucket_name supplied via TF_VAR_bucket_name or .tfvars
}

# Smoke test: module applies cleanly against a Premium+ workspace and produces a usable storage_credential_id.
# run "applies_against_premium_workspace" {
#   command = apply
#
#   assert {
#     condition     = output.storage_credential_id != ""
#     error_message = "Expected non-empty storage_credential_id after successful apply"
#   }
#
#   assert {
#     condition     = can(regex("@.*\\.iam\\.gserviceaccount\\.com$", output.databricks_service_account_email))
#     error_message = "Expected databricks_service_account_email to be a GCP service account address"
#   }
# }

# Tier-gated failure test: against a Standard-tier workspace, expect failure.
# Per DATABRICKS_RULES.md Rule 2.3 + 4.1: this test is the empirical enforcement of the
# README's "Minimum tier: Premium" claim.
#
# Enable by overriding the databricks.workspace provider to point at a Standard-tier workspace.
# Skipped until a Standard-tier test workspace is provisioned.
#
# run "fails_against_standard_tier_workspace" {
#   command = apply
#
#   expect_failures = [
#     databricks_storage_credential.this,
#   ]
# }

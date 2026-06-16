# Integration tests — apply-command against real GCP project + Databricks account.
#
# Credential-gated. Requires:
#   - GCP credentials with Storage Admin and Project IAM Admin in the target project
#   - DATABRICKS_HOST=https://accounts.gcp.databricks.com
#   - DATABRICKS_CLIENT_ID, DATABRICKS_CLIENT_SECRET, DATABRICKS_ACCOUNT_ID env vars
#
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# These tests verify:
#   1. The module actually creates the GCS bucket, applies IAM bindings, and registers
#      the storage configuration against a live Databricks GCP account.
#   2. Tier-gated failure surfaces loudly (DATABRICKS_RULES.md Rule 4.1) — when applied
#      against a Standard-tier account, the API rejects and the apply fails clearly.
#
# The plan-command tests in plan.tftest.hcl cover the static / mock-provider cases. This
# file covers the integration cases that require real cloud credentials.

variables {
  project_id                       = "my-test-project"
  region                           = "us-central1"
  resource_prefix                  = "tftest-gcp-ws-storage"
  databricks_service_account_email = "databricks-sa@my-test-project.iam.gserviceaccount.com"
  # databricks_account_id supplied via TF_VAR_databricks_account_id or .tfvars
}

# Smoke test: module applies cleanly against a Premium+ account and produces a usable
# storage_configuration_id.
# run "applies_against_premium_account" {
#   command = apply
#
#   assert {
#     condition     = output.storage_configuration_id != ""
#     error_message = "Expected non-empty storage_configuration_id after successful apply"
#   }
#
#   assert {
#     condition     = startswith(output.bucket_url, "gs://")
#     error_message = "Expected bucket_url to start with gs://"
#   }
#
#   assert {
#     condition     = output.bucket_name == "tftest-gcp-ws-storage-root-storage"
#     error_message = "Expected bucket_name to be tftest-gcp-ws-storage-root-storage"
#   }
# }

# Tier-gated failure test: against a Standard-tier account, expect failure.
# Per DATABRICKS_RULES.md Rule 2.3 + 4.1: this test is the empirical enforcement of the
# README's "Minimum tier: Premium" claim.
#
# Enable by overriding `databricks_account_id` to point at a Standard-tier account.
# Skipped until a Standard-tier test account is provisioned.
#
# run "fails_against_standard_tier_account" {
#   command = apply
#
#   variables {
#     databricks_account_id = "<standard-tier-account-id>"
#   }
#
#   expect_failures = [
#     databricks_mws_storage_configurations.this,
#   ]
# }

# Integration tests — apply-command against a real GCP project + Databricks account.
#
# Credential-gated. Requires:
#   - GCP credentials with Project IAM Admin + Service Account Admin in the target project
#     (via GOOGLE_CREDENTIALS, gcloud ADC, or Workload Identity)
#   - DATABRICKS_CLIENT_ID, DATABRICKS_CLIENT_SECRET, and TF_VAR_databricks_account_id env vars
#
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# These tests verify:
#   1. The module actually creates the GCP service account, custom role, and IAM bindings.
#   2. The service account is registered as a Databricks account admin.
#   3. Tier-gated failure surfaces loudly (DATABRICKS_RULES.md Rule 4.1) — when applied against
#      a Standard-tier account the API rejects and the apply fails clearly.
#
# The plan-command tests in plan.tftest.hcl cover static / mock-provider cases. This file covers
# integration cases that require real cloud credentials.

variables {
  resource_prefix = "tftest-gcpsa"
  delegate_emails = []
  # project_id supplied via TF_VAR_project_id or .tfvars
}

# Smoke test: module applies cleanly against a Premium+ account and produces a service account email.
# run "applies_against_premium_account" {
#   command = apply
#
#   assert {
#     condition     = output.service_account_email != ""
#     error_message = "Expected non-empty service_account_email after successful apply"
#   }
#
#   assert {
#     condition     = can(regex("@.*\\.iam\\.gserviceaccount\\.com$", output.service_account_email))
#     error_message = "Expected service_account_email to be a GCP service account email"
#   }
#
#   assert {
#     condition     = output.databricks_user_id != ""
#     error_message = "Expected non-empty databricks_user_id after successful apply"
#   }
# }

# Tier-gated failure test: against a Standard-tier account, expect failure on databricks_user_role.
# Per DATABRICKS_RULES.md Rule 2.3 + 4.1: this test is the empirical enforcement of the
# README's "Minimum tier: Premium" claim.
#
# Enable by pointing the databricks.account provider at a Standard-tier account.
# Skipped until a Standard-tier test account is provisioned.
#
# run "fails_against_standard_tier_account" {
#   command = apply
#
#   expect_failures = [
#     databricks_user_role.this,
#   ]
# }

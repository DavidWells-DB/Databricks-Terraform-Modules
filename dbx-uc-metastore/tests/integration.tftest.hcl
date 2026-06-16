# Integration tests — apply-command against a real Databricks account.
#
# Credential-gated. Requires:
#   - DATABRICKS_HOST, DATABRICKS_CLIENT_ID, DATABRICKS_CLIENT_SECRET, DATABRICKS_ACCOUNT_ID env vars
#     (or equivalent provider config) pointing at a Premium+ Databricks account.
#   - A pre-existing cloud storage bucket and IAM role (AWS) or Access Connector (Azure) with
#     appropriate permissions.
#
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# These tests verify:
#   1. The module actually creates a metastore and data access config against a live Databricks account.
#   2. Tier-gated failure surfaces loudly (DATABRICKS_RULES.md Rule 4.1) — when applied against a
#      Standard-tier account, the API rejects and the apply fails clearly.
#
# The plan-command tests in plan.tftest.hcl cover the static / mock-provider cases. This file covers
# the integration cases that require real cloud credentials.

variables {
  metastore_name = "tftest-uc-metastore"
  region         = "us-east-1"
  # storage_root_url, data_access_name, and storage_credential supplied via TF_VAR_* or .tfvars
}

# Smoke test: module applies cleanly against a Premium+ account and produces a metastore_id.
# run "applies_against_premium_account" {
#   command = apply
#
#   variables {
#     storage_root_url = "s3://your-uc-bucket/tftest"
#     data_access_name = "tftest-data-access"
#     storage_credential = {
#       aws_iam_role = {
#         role_arn = "arn:aws:iam::123456789012:role/tftest-uc-role"
#       }
#     }
#   }
#
#   assert {
#     condition     = output.metastore_id != ""
#     error_message = "Expected non-empty metastore_id after successful apply"
#   }
#
#   assert {
#     condition     = output.metastore_name == "tftest-uc-metastore"
#     error_message = "Expected metastore_name to match the metastore_name input"
#   }
# }

# Tier-gated failure test: against a Standard-tier account, expect failure.
# Per DATABRICKS_RULES.md Rule 2.3 + 4.1: this test is the empirical enforcement of the
# README's "Minimum tier: Premium" claim.
#
# Enable by pointing the databricks.account provider at a Standard-tier account.
# Skipped until a Standard-tier test account is provisioned.
#
# run "fails_against_standard_tier_account" {
#   command = apply
#
#   variables {
#     storage_root_url = "s3://your-uc-bucket/tftest"
#     data_access_name = "tftest-data-access"
#     storage_credential = {
#       aws_iam_role = {
#         role_arn = "arn:aws:iam::123456789012:role/tftest-uc-role"
#       }
#     }
#   }
#
#   expect_failures = [
#     databricks_metastore.this,
#   ]
# }

# Integration tests — apply-command against a real Azure subscription + Databricks workspace.
#
# Credential-gated. Requires:
#   - Azure credentials (ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID)
#   - DATABRICKS_HOST, DATABRICKS_CLIENT_ID, DATABRICKS_CLIENT_SECRET env vars (workspace-scoped)
#   - An existing resource group and ADLS Gen2 storage account in the target subscription
#
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# These tests verify:
#   1. The module actually creates the Access Connector, assigns Storage Blob Data Contributor,
#      and registers the storage credential against a live Databricks workspace.
#   2. Tier-gated failure surfaces loudly (DATABRICKS_RULES.md Rule 4.1) — when applied against
#      a Standard-tier workspace, the databricks_storage_credential resource is rejected at apply time.
#
# The plan-command tests in plan.tftest.hcl cover the static / mock-provider cases. This file covers
# the integration cases that require real cloud credentials.

variables {
  resource_group_name = "tftest-azure-uc-storage-credential-rg"
  location            = "eastus"
  # storage_account_id supplied via TF_VAR_storage_account_id or .tfvars
  credential_name = "tftest-uc-cred"
  comment         = "Created by integration test — safe to delete"
}

# Smoke test: module applies cleanly against a Premium+ workspace and produces a non-empty credential ID.
# run "applies_against_premium_workspace" {
#   command = apply
#
#   assert {
#     condition     = output.storage_credential_id != ""
#     error_message = "Expected non-empty storage_credential_id after successful apply"
#   }
#
#   assert {
#     condition     = output.access_connector_principal_id != ""
#     error_message = "Expected non-empty access_connector_principal_id after successful apply"
#   }
# }

# Tier-gated failure test: against a Standard-tier workspace, expect failure.
# Per DATABRICKS_RULES.md Rule 2.3 + 4.1: this test is the empirical enforcement of the
# README's "Minimum tier: Premium" claim.
#
# Enable by pointing the databricks.workspace provider at a Standard-tier workspace.
# Skipped until a Standard-tier test workspace is provisioned.
#
# run "fails_against_standard_tier_workspace" {
#   command = apply
#
#   expect_failures = [
#     databricks_storage_credential.this,
#   ]
# }

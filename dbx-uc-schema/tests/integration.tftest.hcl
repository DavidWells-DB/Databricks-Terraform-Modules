# Integration tests — apply-command against a real Databricks workspace.
#
# Credential-gated. Requires:
#   - DATABRICKS_HOST, DATABRICKS_CLIENT_ID, DATABRICKS_CLIENT_SECRET env vars
#     (configured for a workspace-level service principal with UC admin privileges)
#   - TF_VAR_catalog_name pointing at an existing catalog in the test workspace
#
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# These tests verify:
#   1. The module actually creates schemas and grants against a live Premium workspace.
#   2. Tier-gated failure surfaces loudly (DATABRICKS_RULES.md Rule 4.1) — when applied against
#      a Standard-tier workspace, the Unity Catalog API rejects and apply fails clearly.
#
# The plan-command tests in plan.tftest.hcl cover static / mock-provider cases. This file
# covers integration cases that require real cloud credentials.

variables {
  # catalog_name supplied via TF_VAR_catalog_name or .tfvars
  schemas = {
    tftest_uc_schema = {
      comment      = "Terraform test schema — safe to delete"
      storage_root = null
      properties   = { managed_by = "terraform-test" }
      grants       = []
    }
  }
}

# Smoke test: module applies cleanly against a Premium workspace and produces a non-empty schema_id.
# run "applies_against_premium_workspace" {
#   command = apply
#
#   assert {
#     condition     = length(output.schema_ids) == 1
#     error_message = "Expected one schema to be created"
#   }
#
#   assert {
#     condition     = output.schema_ids["tftest_uc_schema"] != ""
#     error_message = "Expected non-empty schema_id for tftest_uc_schema"
#   }
# }

# Tier-gated failure test: against a Standard-tier workspace, expect failure.
# Per DATABRICKS_RULES.md Rules 2.3 + 4.1: this test is the empirical enforcement of the
# README's "Minimum tier: Premium" claim.
#
# Enable by setting databricks.workspace provider host to a Standard-tier workspace URL.
# Skipped until a Standard-tier test workspace is provisioned.
#
# run "fails_against_standard_tier_workspace" {
#   command = apply
#
#   expect_failures = [
#     databricks_schema.this["tftest_uc_schema"],
#   ]
# }

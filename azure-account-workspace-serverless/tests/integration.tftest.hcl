# Integration tests — apply-command against a real Azure subscription.
#
# Credential-gated. Requires:
#   - Azure credentials configured (ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID
#     or equivalent az login / managed identity)
#   - The target resource group must already exist.
#   - The service principal must have Contributor on the resource group.
#
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# These tests verify:
#   1. The module actually creates the workspace against a live Azure subscription.
#   2. Tier-gated failure surfaces loudly (DATABRICKS_RULES.md Rule 4.1) — serverless compute
#      requires premium SKU; applying with standard SKU creates the workspace but serverless
#      will be unavailable (no plan-time check). The tier-failure test below is included as a
#      stub to be enabled when a suitable standard-tier test environment is provisioned.
#
# The plan-command tests in plan.tftest.hcl cover the static / mock-provider cases. This file
# covers the integration cases that require real Azure credentials.

provider "azurerm" {
  features {}
}

variables {
  name     = "tftest-adb-serverless"
  location = "eastus"
  # Required — supply via TF_VAR_* env vars or a .tfvars file:
  #   resource_group_name (pre-existing resource group)
}

# Smoke test: module applies cleanly and produces a usable workspace_url.
run "applies_and_produces_workspace_url" {
  command = apply

  assert {
    condition     = startswith(output.workspace_url, "https://adb-")
    error_message = "Expected workspace_url to start with https://adb-"
  }

  assert {
    condition     = output.workspace_resource_id != ""
    error_message = "Expected non-empty workspace_resource_id after successful apply"
  }
}

# Tier-gated failure test: with sku = "standard", serverless compute features will be
# unavailable. The provider does not reject standard at plan time — failure is silent at
# the Databricks feature level rather than at apply time for workspace creation.
# Per DATABRICKS_RULES.md Rule 2.3 + 4.1: document empirical enforcement here.
# This test is a placeholder; enable when a standard-tier test scenario is wired.
#
# run "standard_sku_workspace_lacks_serverless" {
#   command = apply
#
#   variables {
#     sku = "standard"
#   }
#
#   # Serverless compute will be silently unavailable; workspace creation succeeds.
#   # The tier enforcement is a Databricks feature-level concern, not provider-level.
#   # Document via README minimum tier claim and verify serverless is gated at the
#   # workspace feature level post-apply.
# }

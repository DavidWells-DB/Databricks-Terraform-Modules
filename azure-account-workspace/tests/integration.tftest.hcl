# Integration tests — apply-command against a real Azure subscription + Databricks account.
#
# Credential-gated. Requires:
#   - ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID env vars
#     (or az login on the runner)
#   - An existing Azure resource group in the target subscription
#   - TF_VAR_resource_group_id (full ARM resource-group id) and TF_VAR_location set (or a tfvars file)
#
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# These tests verify:
#   1. The module actually creates an Azure Databricks workspace.
#   2. The workspace URL and resource ID are non-empty after apply.
#   3. Tier-gated failure surfaces loudly (the Databricks module rules Rule 4.1) — when applied
#      against a Standard-tier workspace, premium features fail at apply time.
#
# The plan-command tests in plan.tftest.hcl cover the static / mock-provider cases.

provider "azurerm" {
  features {}
}

provider "azapi" {}

variables {
  name     = "tftest-azure-workspace"
  location = "eastus"
  sku      = "premium"
  # Required — supply via TF_VAR_* env vars or a .tfvars file:
  #   resource_group_id (pre-existing resource group, full ARM id)
}

# Smoke test: module applies cleanly against a Premium subscription and produces a workspace.
run "applies_and_produces_workspace_url" {
  command = apply

  assert {
    condition     = output.workspace_url != ""
    error_message = "Expected non-empty workspace_url after successful apply"
  }

  assert {
    condition     = output.workspace_resource_id != ""
    error_message = "Expected non-empty workspace_resource_id after successful apply"
  }

  assert {
    condition     = output.compute_mode == "Hybrid"
    error_message = "Live workspace must report ARM computeMode == \"Hybrid\" (this module's classic type — anything else means the deployed workspace is not what the module promises)"
  }

  assert {
    condition     = output.is_uc_enabled == true
    error_message = "Live workspace must report properties.isUcEnabled == true — with defaultCatalog.initialType = \"UnityCatalog\" the workspace should be UC-enabled at creation"
  }
}

# Tier-gated failure test: enhanced security features require the Enhanced Security and
# Compliance add-on. Against a workspace without the add-on, apply should fail loudly.
# Per the Databricks module rules Rule 2.3 + 4.1: this test is the empirical enforcement of the
# README's "Minimum tier: Premium / Enhanced Security and Compliance add-on" claim.
#
# Enable by targeting a subscription without the Enhanced Security add-on.
# Skipped until a suitable test subscription is provisioned.
#
# run "fails_against_workspace_without_esc_addon" {
#   command = apply
#
#   variables {
#     compliance_security_profile_enabled = true
#   }
#
#   expect_failures = [
#     azapi_resource.this,
#   ]
# }


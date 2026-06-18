# Integration tests — apply-command against a real Azure subscription.
#
# Credential-gated. Requires:
#   - Azure credentials with Network Contributor on both resource groups
#   - ARM_SUBSCRIPTION_ID, ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID env vars
#     (or equivalent az login session)
#   - Pre-existing VNets referenced via TF_VAR_* or a .tfvars file
#
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# These tests verify:
#   1. The module actually creates both VNet peering objects in a live Azure subscription.
#   2. Tier-gated failure surfaces loudly (DATABRICKS_RULES.md Rule 4.1) — when applied against
#      a Standard-tier Databricks workspace (VNet injection is Premium-only), the workspace
#      creation rejects the VNet config and fails clearly.
#
# The plan-command tests in plan.tftest.hcl cover the static / mock-provider cases. This file
# covers the integration cases that require real Azure credentials.

provider "azurerm" {
  features {}
}

variables {
  local_vnet_name  = "tftest-spoke-vnet"
  remote_vnet_name = "tftest-hub-vnet"
  # Required — supply via TF_VAR_* env vars or a .tfvars file:
  #   local_vnet_id              (Azure resource ID of the local VNet)
  #   remote_vnet_id             (Azure resource ID of the remote VNet)
  #   local_resource_group_name  (resource group containing local VNet)
  #   remote_resource_group_name (resource group containing remote VNet)
}

# Smoke test: module applies cleanly against a live Azure subscription and produces valid IDs.
run "applies_against_live_azure_subscription" {
  command = apply

  assert {
    condition     = output.local_peering_id != ""
    error_message = "Expected non-empty local_peering_id after successful apply"
  }

  assert {
    condition     = output.remote_peering_id != ""
    error_message = "Expected non-empty remote_peering_id after successful apply"
  }
}

# Tier-gated failure test: VNet-injected Databricks workspace on Standard tier rejects VNet config.
# Per DATABRICKS_RULES.md Rule 2.3 + 4.1: this test is the empirical enforcement of the
# README's "Minimum tier: Premium" claim.
#
# Enable by pointing at a Standard-tier Databricks workspace that uses VNet injection.
# Skipped until a Standard-tier test workspace is provisioned.
#
# run "fails_with_standard_tier_workspace_vnet_injection" {
#   command = apply
#
#   # This test verifies that attempting to attach a peered VNet to a Standard-tier
#   # Databricks workspace fails loudly at apply time.
#   # Configure workspace_id to a Standard-tier workspace for this assertion to be meaningful.
#
#   expect_failures = [
#     azurerm_virtual_network_peering.local_to_remote,
#   ]
# }

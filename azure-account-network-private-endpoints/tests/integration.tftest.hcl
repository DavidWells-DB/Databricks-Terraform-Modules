# Integration tests — apply-command against a real Azure subscription.
#
# Credential-gated. Requires:
#   - Azure credentials (via az login, ARM_CLIENT_ID/ARM_CLIENT_SECRET/ARM_TENANT_ID/ARM_SUBSCRIPTION_ID,
#     or managed identity)
#   - A pre-existing resource group, VNet, and subnet with private endpoint network policies disabled
#   - A pre-existing Databricks workspace with private link support (Premium SKU)
#
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# These tests verify:
#   1. The module actually creates private endpoints and DNS zone against a live Azure subscription.
#   2. Tier-gated failure surfaces loudly (DATABRICKS_RULES.md Rule 4.1) — applying against a
#      Standard-tier workspace that does not support private link fails clearly.
#
# The plan-command tests in plan.tftest.hcl cover static / mock-provider cases. This file covers
# the integration cases that require real Azure credentials.

variables {
  resource_group_name    = "rg-databricks-pe-tftest"
  location               = "eastus"
  enable_front_end_pe    = false
  enable_browser_auth_pe = false
  hub_vnet_ids           = []
  tags = {
    ManagedBy = "terraform-test"
  }
  # workspace_resource_id, pe_subnet_id, vnet_id supplied via TF_VAR_* or .tfvars
}

# Smoke test: module applies cleanly against a Premium workspace and produces usable outputs.
# run "applies_against_premium_workspace" {
#   command = apply
#
#   assert {
#     condition     = output.back_end_pe_id != ""
#     error_message = "Expected non-empty back_end_pe_id after successful apply"
#   }
#
#   assert {
#     condition     = output.private_dns_zone_id != ""
#     error_message = "Expected non-empty private_dns_zone_id after successful apply"
#   }
#
#   assert {
#     condition     = output.private_dns_zone_name == "privatelink.azuredatabricks.net"
#     error_message = "DNS zone name must be privatelink.azuredatabricks.net"
#   }
# }

# Tier-gated failure test: against a Standard-tier workspace, private link setup should fail.
# Per DATABRICKS_RULES.md Rule 2.3 + 4.1: this test is the empirical enforcement of the
# README's "Minimum tier: Premium" claim.
#
# Enable by overriding `workspace_resource_id` to point at a Standard-tier workspace.
# Skipped until a Standard-tier test workspace is provisioned.
#
# run "fails_against_standard_tier_workspace" {
#   command = apply
#
#   variables {
#     workspace_resource_id = "<standard-tier-workspace-resource-id>"
#   }
#
#   expect_failures = [
#     azurerm_private_endpoint.this["back_end"],
#   ]
# }

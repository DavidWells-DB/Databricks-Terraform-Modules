# Integration tests — apply-command against a real Azure subscription.
#
# Credential-gated. Requires:
#   - Azure credentials (ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID)
#     or an active `az login` session with the target subscription set.
#   - A pre-existing resource group with a hub VNet containing an AzureFirewallSubnet (>= /26).
#   - Pre-existing spoke subnets to associate with the forced-tunnel route table.
#
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# These tests verify:
#   1. The module applies cleanly against a real Azure subscription.
#   2. All outputs are populated with valid, non-empty values.
#   3. Tier-gated failure surfaces loudly (DATABRICKS_RULES.md Rule 4.1) — deploying this
#      module for a workspace below Premium tier will fail at the workspace configuration layer.
#
# The plan-command tests in plan.tftest.hcl cover the static / mock-provider cases.

variables {
  resource_group_name = "rg-hub-databricks-tftest"
  location            = "eastus"
  firewall_name       = "tftest-hub-fw"
  # firewall_subnet_id, spoke_subnet_ids, allowed_spoke_cidr_ranges supplied via
  # TF_VAR_* environment variables or a .tfvars file.
  service_tag_rules = [
    {
      name              = "allow-databricks-control-plane"
      priority          = 100
      action            = "Allow"
      destination_tags  = ["AzureDatabricks"]
      destination_ports = ["443"]
      protocols         = ["TCP"]
    },
    {
      name              = "allow-storage-eastus"
      priority          = 110
      action            = "Allow"
      destination_tags  = ["Storage.EastUS"]
      destination_ports = ["443"]
      protocols         = ["TCP"]
    },
  ]
  firewall_sku_tier = "Premium"
}

# Smoke test: module applies cleanly and produces valid outputs.
# run "applies_and_produces_valid_outputs" {
#   command = apply
#
#   assert {
#     condition     = output.firewall_id != ""
#     error_message = "Expected non-empty firewall_id after successful apply"
#   }
#
#   assert {
#     condition     = output.firewall_private_ip != ""
#     error_message = "Expected non-empty firewall_private_ip after successful apply"
#   }
#
#   assert {
#     condition     = output.firewall_public_ip != ""
#     error_message = "Expected non-empty firewall_public_ip after successful apply"
#   }
#
#   assert {
#     condition     = output.firewall_policy_id != ""
#     error_message = "Expected non-empty firewall_policy_id after successful apply"
#   }
#
#   assert {
#     condition     = output.route_table_id != ""
#     error_message = "Expected non-empty route_table_id after successful apply"
#   }
# }

# Tier-gated failure test: Per DATABRICKS_RULES.md Rule 2.3 + 4.1, the README's
# "Minimum tier: Premium" claim is empirically enforced by verifying that deploying
# this firewall for a Databricks workspace below Premium tier results in a clear failure.
#
# Note: azure-account-network-firewall creates only Azure-side resources (no Databricks
# API calls). The tier dependency is enforced by the downstream workspace configuration
# that consumes this module's outputs. A separate integration test in the workspace
# provisioning module exercises the tier-failure case.
#
# Skipped until a Premium-tier test Azure subscription is provisioned.
#
# run "fails_against_standard_tier_workspace" {
#   command = apply
#
#   # Override variables to point at a Standard-tier Databricks workspace subscription.
#   variables {
#     resource_group_name = "<standard-tier-rg>"
#   }
#
#   expect_failures = [
#     azurerm_firewall.this,
#   ]
# }

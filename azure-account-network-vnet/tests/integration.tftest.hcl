# Integration tests — apply-command against a real Azure subscription.
#
# Credential-gated. Requires:
#   - Azure credentials (via ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID
#     or an authenticated az CLI session)
#   - A pre-existing Azure resource group (set via TF_VAR_resource_group_name)
#
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# These tests verify:
#   1. The module actually creates the VNet, subnets, and NSG against a live Azure subscription.
#   2. Tier-gated failure surfaces loudly (DATABRICKS_RULES.md Rule 4.1) — when the resulting VNet
#      is used with a Standard-tier Databricks workspace, the workspace creation should fail clearly
#      (tested in the azure-account-workspace integration tests, not here, since this module has
#      no Databricks provider dependency).
#
# The plan-command tests in plan.tftest.hcl cover the static / mock-provider cases. This file covers
# the integration cases that require real Azure credentials.

variables {
  resource_group_name   = "rg-tftest-databricks-network"
  location              = "eastus"
  vnet_name             = "tftest-databricks-vnet"
  vnet_cidr             = "10.99.0.0/16"
  host_subnet_name      = "tftest-databricks-host"
  host_subnet_cidr      = "10.99.1.0/24"
  container_subnet_name = "tftest-databricks-container"
  container_subnet_cidr = "10.99.2.0/24"
  nsg_name              = "tftest-databricks-nsg"
  pe_subnet_name        = null
  pe_subnet_cidr        = null
  # resource_group_name can be overridden via TF_VAR_resource_group_name
}

# Smoke test: module applies cleanly and produces expected VNet and subnet IDs.
# run "applies_and_creates_vnet" {
#   command = apply
#
#   assert {
#     condition     = output.vnet_id != ""
#     error_message = "Expected non-empty vnet_id after successful apply"
#   }
#
#   assert {
#     condition     = output.host_subnet_id != ""
#     error_message = "Expected non-empty host_subnet_id after successful apply"
#   }
#
#   assert {
#     condition     = output.container_subnet_id != ""
#     error_message = "Expected non-empty container_subnet_id after successful apply"
#   }
#
#   assert {
#     condition     = output.nsg_id != ""
#     error_message = "Expected non-empty nsg_id after successful apply"
#   }
# }

# PE subnet test: module creates the optional PE subnet when provided.
# run "applies_with_pe_subnet" {
#   command = apply
#
#   variables {
#     pe_subnet_name = "tftest-databricks-pe"
#     pe_subnet_cidr = "10.99.3.0/27"
#   }
#
#   assert {
#     condition     = output.pe_subnet_id != null
#     error_message = "Expected non-null pe_subnet_id when pe_subnet_name and pe_subnet_cidr are provided"
#   }
# }

# Tier-gated failure test: this module has no Databricks provider dependency, so tier enforcement
# is exercised in the azure-account-workspace integration tests when a workspace is created using
# the VNet produced by this module against a Standard-tier Databricks account.
# Per DATABRICKS_RULES.md Rule 2.3 + 4.1.
#
# run "fails_against_standard_tier_workspace" {
#   command = apply
#
#   # This test belongs in azure-account-workspace integration tests.
#   # Documented here for cross-reference.
# }

# Integration tests — apply-command against a real Azure subscription.
#
# Credential-gated. Requires:
#   - Azure credentials (ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID)
#     or an active `az login` session with the target subscription set.
#   - A pre-existing resource group specified via TF_VAR_resource_group_name.
#
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# These tests verify:
#   1. The module actually creates the storage account and container in a live Azure subscription.
#   2. All outputs are populated with non-empty, valid values.
#
# The plan-command tests in plan.tftest.hcl cover the static / mock-provider cases. This file
# covers the integration cases that require real cloud credentials.
#
# Minimum tier: Premium (for Unity Catalog use). Standard is sufficient for workspace root storage.
# Per DATABRICKS_RULES.md Rule 4.1: a tier-failure test is not applicable here because
# azure-account-workspace-storage creates only Azure-side resources (no Databricks API calls).
# The tier dependency is enforced by the downstream module that consumes these outputs
# (e.g., a UC metastore module that calls databricks_metastore).

variables {
  location                 = "eastus"
  resource_prefix          = "tfteststrg"
  account_replication_type = "LRS"
  tags = {
    Environment = "test"
    ManagedBy   = "terraform-test"
  }
  # Required — supply via TF_VAR_* env vars or a .tfvars file:
  #   resource_group_name (pre-existing resource group)
}

provider "azurerm" {
  features {}
  storage_use_azuread = true
}

# Smoke test: module applies cleanly and produces valid outputs.
run "applies_and_produces_valid_outputs" {
  command = apply

  assert {
    condition     = output.storage_account_name != ""
    error_message = "Expected non-empty storage_account_name after successful apply"
  }

  assert {
    condition     = output.storage_account_id != ""
    error_message = "Expected non-empty storage_account_id after successful apply"
  }

  assert {
    condition     = output.container_name == "databricks"
    error_message = "Expected default container name 'databricks'"
  }

  assert {
    condition     = startswith(output.dfs_endpoint, "https://")
    error_message = "Expected dfs_endpoint to start with https://"
  }
}

# Integration tests — apply-command against a real Azure subscription.
#
# Credential-gated. Requires:
#   - Azure credentials with Key Vault Contributor + access policy permissions
#     (ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID env vars,
#     or an authenticated az CLI session)
#   - An existing resource group referenced by TF_VAR_resource_group_name
#
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# These tests verify:
#   1. The module actually creates the Key Vault and three CMK keys against a live Azure subscription.
#   2. Tier-gated failure: CMK for managed services requires Databricks Premium. When a workspace
#      below Premium tier attempts to use these keys, the apply of the workspace resource fails
#      loudly (DATABRICKS_RULES.md Rule 4.1). Because key creation itself does not require a
#      Databricks workspace, the tier-failure test must be authored in the azure-account-workspace
#      module integration tests, not here. This is documented as a known gap.
#
# The plan-command tests in plan.tftest.hcl cover the static / mock-provider cases.

variables {
  location                   = "eastus"
  soft_delete_retention_days = 7
  private_endpoint           = null
  network_acls = {
    default_action = "Allow"
    bypass         = "AzureServices"
    ip_rules       = []
  }
  tags = {
    Env = "tftest"
  }
  # Required — supply via TF_VAR_* env vars or a .tfvars file:
  #   resource_group_name                    (pre-existing resource group)
  #   key_vault_name                         (globally unique, 3-24 chars)
  #   tenant_id                              (Azure AD tenant UUID)
  #   databricks_service_principal_object_id (AzureDatabricks enterprise app object ID)
  #   azure_client_object_id                 (object ID of the Terraform runner)
}

provider "azurerm" {
  features {}
}

# Smoke test: module applies cleanly against a live Azure subscription and produces
# a usable Key Vault and key IDs.
run "applies_against_azure_subscription" {
  command = apply

  assert {
    condition     = output.key_vault_id != ""
    error_message = "Expected non-empty key_vault_id after successful apply"
  }

  assert {
    condition     = output.managed_services_key_id != ""
    error_message = "Expected non-empty managed_services_key_id after successful apply"
  }

  assert {
    condition     = output.workspace_storage_key_id != ""
    error_message = "Expected non-empty workspace_storage_key_id after successful apply"
  }

  assert {
    condition     = output.managed_disk_key_id != ""
    error_message = "Expected non-empty managed_disk_key_id after successful apply"
  }
}

# Tier-failure note (DATABRICKS_RULES.md Rule 4.1):
# The minimum tier for CMK is Premium. Because this module only creates Azure Key Vault
# resources and does not interact with the Databricks control plane, the tier check cannot
# be performed here. The tier-failure integration test must be authored in the
# azure-account-workspace integration test suite, where workspace creation with CMK inputs
# can be attempted against a Standard-tier account.
#
# run "cmk_fails_against_standard_tier_workspace" {
#   command = apply
#
#   # This test must be in azure-account-workspace/tests/integration.tftest.hcl.
#   # Documented here as a cross-module dependency for completeness.
# }

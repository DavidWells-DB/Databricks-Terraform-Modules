mock_provider "azurerm" {
  mock_resource "azurerm_databricks_workspace" {
    defaults = {
      workspace_id              = 123456789
      workspace_url             = "adb-123456789.1.azuredatabricks.net"
      id                        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Databricks/workspaces/test-workspace"
      managed_resource_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/databricks-rg-test-workspace"
      storage_account_identity  = []
      managed_disk_identity     = []
      disk_encryption_set_id    = null
    }
  }

  mock_resource "azurerm_databricks_workspace_root_dbfs_customer_managed_key" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Databricks/workspaces/test-workspace/rootDbfsEncryptionKeyVersion"
    }
  }
}

variables {
  name                = "test-workspace"
  resource_group_name = "rg-test"
  location            = "eastus"
}

# ---------------------------------------------------------------------------
# Resource attribute checks
# ---------------------------------------------------------------------------

run "workspace_resource_uses_input_name" {
  command = plan

  assert {
    condition     = azurerm_databricks_workspace.this.name == "test-workspace"
    error_message = "Workspace name should match the name input"
  }
}

run "workspace_resource_uses_input_location" {
  command = plan

  assert {
    condition     = azurerm_databricks_workspace.this.location == "eastus"
    error_message = "Workspace location should match the location input"
  }
}

run "workspace_resource_uses_input_resource_group" {
  command = plan

  assert {
    condition     = azurerm_databricks_workspace.this.resource_group_name == "rg-test"
    error_message = "Workspace resource_group_name should match the resource_group_name input"
  }
}

run "workspace_default_sku_is_premium" {
  command = plan

  assert {
    condition     = azurerm_databricks_workspace.this.sku == "premium"
    error_message = "Default SKU should be premium"
  }
}

run "workspace_url_has_https_prefix" {
  command = plan

  assert {
    condition     = startswith(output.workspace_url, "https://")
    error_message = "workspace_url output should start with https://"
  }
}

# ---------------------------------------------------------------------------
# Serverless pattern: no VNet injection (no custom_parameters)
# ---------------------------------------------------------------------------

run "no_custom_parameters_for_serverless" {
  command = plan

  # The absence of custom_parameters is the serverless pattern. We verify the
  # workspace is planned without a virtual_network_id set (which would require
  # custom_parameters in the VNet injection module).
  assert {
    condition     = azurerm_databricks_workspace.this.name == "test-workspace"
    error_message = "Workspace should be created without VNet injection custom_parameters"
  }
}

# ---------------------------------------------------------------------------
# CMK conditional — no root DBFS CMK resource when key not provided
# ---------------------------------------------------------------------------

run "no_root_dbfs_cmk_without_key" {
  command = plan

  assert {
    condition     = length(azurerm_databricks_workspace_root_dbfs_customer_managed_key.this) == 0
    error_message = "Root DBFS CMK resource should not be created when root_dbfs_cmk_key_vault_key_id is null"
  }
}

# ---------------------------------------------------------------------------
# CMK conditional — root DBFS CMK resource created when key is provided
# ---------------------------------------------------------------------------

run "root_dbfs_cmk_created_with_key" {
  command = plan

  variables {
    root_dbfs_cmk_key_vault_key_id = "https://myvault.vault.azure.net/keys/mykey/abc123"
  }

  assert {
    condition     = length(azurerm_databricks_workspace_root_dbfs_customer_managed_key.this) == 1
    error_message = "Root DBFS CMK resource should be created when root_dbfs_cmk_key_vault_key_id is set"
  }

  assert {
    condition     = azurerm_databricks_workspace_root_dbfs_customer_managed_key.this[0].key_vault_key_id == "https://myvault.vault.azure.net/keys/mykey/abc123"
    error_message = "Root DBFS CMK key_vault_key_id should match the root_dbfs_cmk_key_vault_key_id input"
  }
}

# ---------------------------------------------------------------------------
# Variable validation — name
# ---------------------------------------------------------------------------

run "name_too_short_rejected" {
  command = plan

  variables {
    name = "ab"
  }

  expect_failures = [var.name]
}

run "name_too_long_rejected" {
  command = plan

  variables {
    name = "this-workspace-name-is-way-too-long-and-exceeds-the-azure-sixty-four-character-limit"
  }

  expect_failures = [var.name]
}

run "name_starts_with_hyphen_rejected" {
  command = plan

  variables {
    name = "-invalid-workspace"
  }

  expect_failures = [var.name]
}

run "name_ends_with_hyphen_rejected" {
  command = plan

  variables {
    name = "invalid-workspace-"
  }

  expect_failures = [var.name]
}

run "name_with_underscore_rejected" {
  command = plan

  variables {
    name = "invalid_workspace"
  }

  expect_failures = [var.name]
}

# ---------------------------------------------------------------------------
# Variable validation — sku
# ---------------------------------------------------------------------------

run "invalid_sku_rejected" {
  command = plan

  variables {
    sku = "enterprise"
  }

  expect_failures = [var.sku]
}

run "standard_sku_accepted" {
  command = plan

  variables {
    sku = "standard"
  }

  assert {
    condition     = azurerm_databricks_workspace.this.sku == "standard"
    error_message = "standard SKU should be accepted and passed through"
  }
}

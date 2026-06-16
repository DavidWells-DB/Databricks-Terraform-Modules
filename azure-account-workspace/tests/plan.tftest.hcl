mock_provider "azurerm" {
  mock_resource "azurerm_databricks_workspace" {
    defaults = {
      id                        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Databricks/workspaces/test-workspace"
      workspace_id              = 1234567890
      workspace_url             = "adb-1234567890.1.azuredatabricks.net"
      managed_resource_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-managed-rg"
      storage_account_identity  = []
      managed_disk_identity     = []
      disk_encryption_set_id    = null
    }
  }

  mock_resource "azurerm_databricks_workspace_root_dbfs_customer_managed_key" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Databricks/workspaces/test-workspace"
    }
  }
}

mock_provider "azapi" {
  mock_resource "azapi_update_resource" {
    defaults = {
      id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Databricks/workspaces/test-workspace"
      output = {}
    }
  }
}

variables {
  name                = "test-workspace"
  resource_group_name = "test-rg"
  location            = "eastus"
}

# --- Workspace name and defaults ---

run "workspace_resource_uses_input_name" {
  command = plan

  assert {
    condition     = azurerm_databricks_workspace.this.name == "test-workspace"
    error_message = "Workspace name should match the name input"
  }
}

run "default_sku_is_premium" {
  command = plan

  assert {
    condition     = azurerm_databricks_workspace.this.sku == "premium"
    error_message = "Default SKU should be premium"
  }
}

# --- VNet injection conditional ---

run "vnet_injection_disabled_when_no_vnet_id" {
  command = plan

  assert {
    condition     = local.vnet_injection_enabled == false
    error_message = "vnet_injection_enabled should be false when virtual_network_id is null"
  }
}

run "vnet_injection_enabled_when_vnet_id_set" {
  command = plan

  variables {
    virtual_network_id                                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/net-rg/providers/Microsoft.Network/virtualNetworks/my-vnet"
    host_subnet_name                                     = "databricks-public"
    container_subnet_name                                = "databricks-private"
    public_subnet_network_security_group_association_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/net-rg/providers/Microsoft.Network/virtualNetworks/my-vnet/subnets/databricks-public/providers/Microsoft.Network/networkSecurityGroups/public-nsg"
    private_subnet_network_security_group_association_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/net-rg/providers/Microsoft.Network/virtualNetworks/my-vnet/subnets/databricks-private/providers/Microsoft.Network/networkSecurityGroups/private-nsg"
  }

  assert {
    condition     = local.vnet_injection_enabled == true
    error_message = "vnet_injection_enabled should be true when virtual_network_id is set"
  }
}

# --- Root DBFS CMK conditional ---

run "root_dbfs_cmk_disabled_by_default" {
  command = plan

  assert {
    condition     = local.root_dbfs_cmk_enabled == false
    error_message = "root_dbfs_cmk_enabled should be false when root_dbfs_cmk_key_vault_key_id is null"
  }
}

run "root_dbfs_cmk_enabled_when_key_set" {
  command = plan

  variables {
    root_dbfs_cmk_key_vault_key_id = "https://my-kv.vault.azure.net/keys/my-key/abc123"
  }

  assert {
    condition     = local.root_dbfs_cmk_enabled == true
    error_message = "root_dbfs_cmk_enabled should be true when root_dbfs_cmk_key_vault_key_id is set"
  }

  assert {
    condition     = length(azurerm_databricks_workspace_root_dbfs_customer_managed_key.this) == 1
    error_message = "Root DBFS CMK resource should be created when key is set"
  }
}

# --- Extended compliance standards / azapi conditional ---

run "azapi_compliance_not_needed_by_default" {
  command = plan

  assert {
    condition     = local.azapi_compliance_needed == false
    error_message = "azapi_compliance_needed should be false when no extended standards are set"
  }
}

run "azapi_compliance_needed_with_extended_standards" {
  command = plan

  variables {
    compliance_security_profile_enabled = true
    extended_compliance_standards       = ["HITRUST"]
  }

  assert {
    condition     = local.azapi_compliance_needed == true
    error_message = "azapi_compliance_needed should be true when extended_compliance_standards is non-empty"
  }

  assert {
    condition     = length(azapi_update_resource.compliance_standards) == 1
    error_message = "azapi_update_resource should be created when azapi_compliance_needed is true"
  }
}

run "all_compliance_standards_merged" {
  command = plan

  variables {
    compliance_security_profile_enabled   = true
    compliance_security_profile_standards = ["HIPAA"]
    extended_compliance_standards         = ["HITRUST"]
  }

  assert {
    condition     = contains(local.all_compliance_standards, "HIPAA") && contains(local.all_compliance_standards, "HITRUST")
    error_message = "all_compliance_standards should contain both azurerm and extended standards"
  }
}

# --- Variable validations ---

run "invalid_sku_rejected" {
  command = plan

  variables {
    sku = "enterprise"
  }

  expect_failures = [var.sku]
}

run "invalid_nsg_rules_rejected" {
  command = plan

  variables {
    network_security_group_rules_required = "InvalidValue"
  }

  expect_failures = [var.network_security_group_rules_required]
}

run "invalid_compliance_standard_rejected" {
  command = plan

  variables {
    compliance_security_profile_enabled   = true
    compliance_security_profile_standards = ["HITRUST"]
  }

  expect_failures = [var.compliance_security_profile_standards]
}

run "invalid_extended_standard_rejected" {
  command = plan

  variables {
    compliance_security_profile_enabled = true
    extended_compliance_standards       = ["INVALID_STANDARD"]
  }

  expect_failures = [var.extended_compliance_standards]
}

run "workspace_name_too_short_rejected" {
  command = plan

  variables {
    name = "ab"
  }

  expect_failures = [var.name]
}

run "workspace_name_invalid_chars_rejected" {
  command = plan

  variables {
    name = "invalid name with spaces!"
  }

  expect_failures = [var.name]
}

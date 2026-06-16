mock_provider "azurerm" {}

variables {
  resource_group_name                    = "rg-databricks-cmk"
  location                               = "eastus"
  key_vault_name                         = "dbx-cmk-test"
  tenant_id                              = "12345678-1234-1234-1234-123456789012"
  databricks_service_principal_object_id = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
  azure_client_object_id                 = "ffffffff-0000-1111-2222-333333333333"
  soft_delete_retention_days             = 7
  private_endpoint                       = null
}

# ---------------------------------------------------------------------------
# Resource attribute assertions
# ---------------------------------------------------------------------------

run "key_vault_uses_premium_sku" {
  command = plan

  assert {
    condition     = azurerm_key_vault.this.sku_name == "premium"
    error_message = "Key Vault must use the premium SKU for Databricks CMK support."
  }
}

run "key_vault_has_purge_protection" {
  command = plan

  assert {
    condition     = azurerm_key_vault.this.purge_protection_enabled == true
    error_message = "Purge protection must be enabled on the Key Vault."
  }
}

run "managed_services_key_is_rsa_2048" {
  command = plan

  assert {
    condition     = azurerm_key_vault_key.managed_services.key_type == "RSA-HSM"
    error_message = "Managed services key must be RSA-HSM type."
  }

  assert {
    condition     = azurerm_key_vault_key.managed_services.key_size == 2048
    error_message = "Managed services key must be 2048-bit."
  }
}

run "workspace_storage_key_is_rsa_2048" {
  command = plan

  assert {
    condition     = azurerm_key_vault_key.workspace_storage.key_type == "RSA-HSM"
    error_message = "Workspace storage key must be RSA-HSM type."
  }

  assert {
    condition     = azurerm_key_vault_key.workspace_storage.key_size == 2048
    error_message = "Workspace storage key must be 2048-bit."
  }
}

run "managed_disk_key_is_rsa_2048" {
  command = plan

  assert {
    condition     = azurerm_key_vault_key.managed_disk.key_type == "RSA-HSM"
    error_message = "Managed disk key must be RSA-HSM type."
  }

  assert {
    condition     = azurerm_key_vault_key.managed_disk.key_size == 2048
    error_message = "Managed disk key must be 2048-bit."
  }
}

run "databricks_access_policy_has_wrap_unwrap" {
  command = plan

  assert {
    condition     = contains(azurerm_key_vault_access_policy.databricks.key_permissions, "WrapKey")
    error_message = "Databricks access policy must include WrapKey permission."
  }

  assert {
    condition     = contains(azurerm_key_vault_access_policy.databricks.key_permissions, "UnwrapKey")
    error_message = "Databricks access policy must include UnwrapKey permission."
  }

  assert {
    condition     = contains(azurerm_key_vault_access_policy.databricks.key_permissions, "Get")
    error_message = "Databricks access policy must include Get permission."
  }
}

# ---------------------------------------------------------------------------
# Private endpoint conditional logic
# ---------------------------------------------------------------------------

run "no_private_endpoint_resources_when_null" {
  command = plan

  variables {
    private_endpoint = null
  }

  assert {
    condition     = length(azurerm_private_endpoint.key_vault) == 0
    error_message = "No private endpoint resource should be created when private_endpoint is null."
  }

  assert {
    condition     = length(azurerm_private_dns_zone.key_vault) == 0
    error_message = "No private DNS zone should be created when private_endpoint is null."
  }
}

run "private_endpoint_resources_created_when_set" {
  command = plan

  variables {
    private_endpoint = {
      subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/pe-subnet"
      vnet_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test"
      resource_group_name = null
    }
  }

  assert {
    condition     = length(azurerm_private_endpoint.key_vault) == 1
    error_message = "One private endpoint resource should be created when private_endpoint is set."
  }

  assert {
    condition     = length(azurerm_private_dns_zone.key_vault) == 1
    error_message = "One private DNS zone should be created when private_endpoint is set."
  }

  assert {
    condition     = length(azurerm_private_dns_zone_virtual_network_link.key_vault) == 1
    error_message = "One VNet link should be created when private_endpoint is set."
  }
}

run "pe_resource_group_falls_back_to_module_rg" {
  command = plan

  variables {
    private_endpoint = {
      subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/pe-subnet"
      vnet_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test"
      resource_group_name = null
    }
  }

  assert {
    condition     = local.pe_resource_group_name == "rg-databricks-cmk"
    error_message = "pe_resource_group_name should fall back to var.resource_group_name when not specified."
  }
}

run "pe_resource_group_uses_override_when_set" {
  command = plan

  variables {
    private_endpoint = {
      subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-pe/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/pe-subnet"
      vnet_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-pe/providers/Microsoft.Network/virtualNetworks/vnet-test"
      resource_group_name = "rg-pe"
    }
  }

  assert {
    condition     = local.pe_resource_group_name == "rg-pe"
    error_message = "pe_resource_group_name should use the override when specified."
  }
}

# ---------------------------------------------------------------------------
# Variable validation: key_vault_name
# ---------------------------------------------------------------------------

run "key_vault_name_too_short_rejected" {
  command = plan

  variables {
    key_vault_name = "ab"
  }

  expect_failures = [var.key_vault_name]
}

run "key_vault_name_too_long_rejected" {
  command = plan

  variables {
    key_vault_name = "this-name-is-way-too-long-for-azure"
  }

  expect_failures = [var.key_vault_name]
}

run "key_vault_name_starts_with_digit_rejected" {
  command = plan

  variables {
    key_vault_name = "1invalid-start"
  }

  expect_failures = [var.key_vault_name]
}

run "key_vault_name_trailing_hyphen_rejected" {
  command = plan

  variables {
    key_vault_name = "invalid-end-"
  }

  expect_failures = [var.key_vault_name]
}

# ---------------------------------------------------------------------------
# Variable validation: UUID fields
# ---------------------------------------------------------------------------

run "invalid_tenant_id_rejected" {
  command = plan

  variables {
    tenant_id = "not-a-valid-uuid"
  }

  expect_failures = [var.tenant_id]
}

run "invalid_databricks_sp_object_id_rejected" {
  command = plan

  variables {
    databricks_service_principal_object_id = "not-a-uuid"
  }

  expect_failures = [var.databricks_service_principal_object_id]
}

run "invalid_azure_client_object_id_rejected" {
  command = plan

  variables {
    azure_client_object_id = "12345-not-uuid"
  }

  expect_failures = [var.azure_client_object_id]
}

# ---------------------------------------------------------------------------
# Variable validation: soft_delete_retention_days
# ---------------------------------------------------------------------------

run "soft_delete_below_minimum_rejected" {
  command = plan

  variables {
    soft_delete_retention_days = 6
  }

  expect_failures = [var.soft_delete_retention_days]
}

run "soft_delete_above_maximum_rejected" {
  command = plan

  variables {
    soft_delete_retention_days = 91
  }

  expect_failures = [var.soft_delete_retention_days]
}

mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Databricks/workspaces/test-workspace"
      output = {
        workspace_id  = "123456789"
        workspace_url = "adb-123456789.1.azuredatabricks.net"
        compute_mode  = "Serverless"
      }
    }
  }
}

variables {
  name              = "test-workspace"
  resource_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
  location          = "eastus2"
}

# ---------------------------------------------------------------------------
# Resource attribute checks
# ---------------------------------------------------------------------------

run "workspace_resource_uses_input_name" {
  command = plan

  assert {
    condition     = azapi_resource.this.name == "test-workspace"
    error_message = "Workspace name should match the name input"
  }
}

run "workspace_resource_uses_input_location" {
  command = plan

  assert {
    condition     = azapi_resource.this.location == "eastus2"
    error_message = "Workspace location should match the location input"
  }
}

run "workspace_resource_uses_input_resource_group" {
  command = plan

  assert {
    condition     = azapi_resource.this.parent_id == var.resource_group_id
    error_message = "Workspace parent_id should match the resource_group_id input"
  }
}

run "workspace_uses_2026_01_01_api" {
  command = plan

  # computeMode only exists in the 2026-01-01 ARM API version — any older pin
  # silently drops back to the Classic managed-VNet workspace type.
  assert {
    condition     = azapi_resource.this.type == "Microsoft.Databricks/workspaces@2026-01-01"
    error_message = "Workspace must be created via the 2026-01-01 ARM API version"
  }
}

# ---------------------------------------------------------------------------
# THE serverless assertion: computeMode = "Serverless"
# ---------------------------------------------------------------------------

run "workspace_is_serverless_compute_mode" {
  command = plan

  assert {
    condition     = azapi_resource.this.body.properties.computeMode == "Serverless"
    error_message = "Workspace must be created with computeMode = \"Serverless\" — the v0.1.0 bug was deploying the Classic managed-VNet type instead"
  }
}

run "workspace_sku_is_premium" {
  command = plan

  assert {
    condition     = azapi_resource.this.body.sku.name == "premium"
    error_message = "Serverless workspaces require the premium SKU"
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
# Public network access mapping
# ---------------------------------------------------------------------------

run "public_network_access_enabled_by_default" {
  command = plan

  assert {
    condition     = azapi_resource.this.body.properties.publicNetworkAccess == "Enabled"
    error_message = "publicNetworkAccess should default to \"Enabled\""
  }
}

run "public_network_access_disabled_maps_to_arm_value" {
  command = plan

  variables {
    public_network_access_enabled = false
  }

  assert {
    condition     = azapi_resource.this.body.properties.publicNetworkAccess == "Disabled"
    error_message = "public_network_access_enabled = false should map to publicNetworkAccess = \"Disabled\""
  }
}

# ---------------------------------------------------------------------------
# Managed-services CMK conditional — omitted when no key is supplied
# ---------------------------------------------------------------------------

run "cmk_omitted_without_key" {
  command = plan

  assert {
    condition     = azapi_resource.this.body.properties.encryption == null
    error_message = "encryption block should be omitted when managed_services_cmk_key_vault_key_id is null"
  }
}

run "cmk_key_id_parsed_into_arm_fields" {
  command = plan

  variables {
    managed_services_cmk_key_vault_key_id = "https://myvault.vault.azure.net/keys/mykey/abc123"
  }

  assert {
    condition = azapi_resource.this.body.properties.encryption.entities.managedServices == {
      keySource = "Microsoft.Keyvault"
      keyVaultProperties = {
        keyName     = "mykey"
        keyVaultUri = "https://myvault.vault.azure.net"
        keyVersion  = "abc123"
      }
    }
    error_message = "Versioned key ID should be parsed into keyName/keyVaultUri/keyVersion"
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
# Variable validation — resource_group_id / managed-services key ID
# ---------------------------------------------------------------------------

run "bare_resource_group_name_rejected" {
  command = plan

  variables {
    resource_group_id = "rg-test"
  }

  expect_failures = [var.resource_group_id]
}

run "unversioned_key_id_rejected" {
  command = plan

  variables {
    managed_services_cmk_key_vault_key_id = "https://myvault.vault.azure.net/keys/mykey"
  }

  expect_failures = [var.managed_services_cmk_key_vault_key_id]
}

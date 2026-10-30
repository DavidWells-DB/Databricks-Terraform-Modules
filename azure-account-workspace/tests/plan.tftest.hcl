mock_provider "azurerm" {
  mock_resource "azurerm_databricks_workspace_root_dbfs_customer_managed_key" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Databricks/workspaces/test-workspace"
    }
  }
}

mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Databricks/workspaces/test-workspace"
      output = {
        workspace_id              = "1234567890"
        workspace_url             = "adb-1234567890.1.azuredatabricks.net"
        managed_resource_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/databricks-rg-test-rg"
        storage_account_identity  = {}
        managed_disk_identity     = {}
        disk_encryption_set_id    = null
        is_uc_enabled             = true
        compute_mode              = "Hybrid"
      }
    }
  }

  mock_resource "azapi_update_resource" {
    defaults = {
      id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Databricks/workspaces/test-workspace"
      output = {}
    }
  }
}

variables {
  name              = "test-workspace"
  resource_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg"
  location          = "eastus"
}

# --- Creation path: azapi, 2026-01-01, Hybrid ---

run "workspace_is_created_via_azapi_2026_01_01" {
  command = plan

  assert {
    condition     = azapi_resource.this.type == "Microsoft.Databricks/workspaces@2026-01-01"
    error_message = "Workspace must be created via the 2026-01-01 ARM API version"
  }

  assert {
    condition     = azapi_resource.this.body.properties.computeMode == "Hybrid"
    error_message = "Workspace must be the classic (Hybrid) compute mode — this module must not drift to the serverless type"
  }

  assert {
    condition     = azapi_resource.this.name == "test-workspace" && azapi_resource.this.parent_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg"
    error_message = "Workspace name and parent resource group should match the inputs"
  }
}

# --- THE fix: defaultCatalog = UnityCatalog ---

run "workspace_catalog_initial_type_is_unity_catalog" {
  command = plan

  # The whole point of the azapi creation path: without this, ARM defaults
  # initialType to HiveMetastore and the workspace default namespace resolves
  # to the legacy hive_metastore catalog.
  assert {
    condition     = azapi_resource.this.body.properties.defaultCatalog.initialType == "UnityCatalog"
    error_message = "defaultCatalog.initialType must be \"UnityCatalog\" so the platform creates a workspace catalog at Day-1"
  }

  # initialName deliberately omitted — the API then names the catalog after the
  # workspace. (Omitted body attributes are absent, not null, hence the keys check.)
  assert {
    condition     = !contains(keys(azapi_resource.this.body.properties.defaultCatalog), "initialName")
    error_message = "initialName should be omitted so the workspace catalog is named after the workspace"
  }
}

run "default_sku_is_premium" {
  command = plan

  assert {
    condition     = azapi_resource.this.body.sku.name == "premium"
    error_message = "Default SKU should be premium"
  }
}

# --- Managed resource group construction ---

run "managed_resource_group_id_defaults_to_databricks_rg_prefix" {
  command = plan

  # azurerm's own default, carried over: databricks-rg-<parent-rg-name>.
  assert {
    condition     = azapi_resource.this.body.properties.managedResourceGroupId == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/databricks-rg-test-rg"
    error_message = "managedResourceGroupId should default to databricks-rg-<resource-group-name> (the azurerm fallback), scoped to the parent's subscription"
  }
}

run "managed_resource_group_id_uses_explicit_name" {
  command = plan

  variables {
    managed_resource_group_name = "my-managed-rg"
  }

  assert {
    condition     = azapi_resource.this.body.properties.managedResourceGroupId == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-managed-rg"
    error_message = "managedResourceGroupId should use the explicit managed_resource_group_name when supplied"
  }
}

# --- VNet injection (wrapped custom parameters) ---

run "vnet_injection_disabled_when_no_vnet_id" {
  command = plan

  assert {
    condition     = local.vnet_injection_enabled == false && azapi_resource.this.body.properties.parameters.customVirtualNetworkId == null
    error_message = "the VNet custom parameters must be null (stripped from the request payload) when virtual_network_id is not set"
  }
}

run "vnet_injection_sends_wrapped_custom_parameters" {
  command = plan

  variables {
    virtual_network_id                                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/net-rg/providers/Microsoft.Network/virtualNetworks/my-vnet"
    host_subnet_name                                     = "databricks-public"
    container_subnet_name                                = "databricks-private"
    public_subnet_network_security_group_association_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/net-rg/providers/Microsoft.Network/virtualNetworks/my-vnet/subnets/databricks-public/providers/Microsoft.Network/networkSecurityGroups/public-nsg"
    private_subnet_network_security_group_association_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/net-rg/providers/Microsoft.Network/virtualNetworks/my-vnet/subnets/databricks-private/providers/Microsoft.Network/networkSecurityGroups/private-nsg"
  }

  assert {
    condition     = azapi_resource.this.body.properties.parameters.customVirtualNetworkId.type == "String" && azapi_resource.this.body.properties.parameters.customVirtualNetworkId.value == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/net-rg/providers/Microsoft.Network/virtualNetworks/my-vnet"
    error_message = "customVirtualNetworkId must be the ARM wrapped form { type = \"String\", value = <vnet id> }"
  }

  assert {
    condition     = azapi_resource.this.body.properties.parameters.customPublicSubnetName.value == "databricks-public" && azapi_resource.this.body.properties.parameters.customPrivateSubnetName.value == "databricks-private"
    error_message = "subnet names must be sent as customPublicSubnetName / customPrivateSubnetName"
  }

  assert {
    condition     = azapi_resource.this.body.properties.parameters.enableNoPublicIp.type == "Bool" && azapi_resource.this.body.properties.parameters.enableNoPublicIp.value == false
    error_message = "enableNoPublicIp must be the ARM wrapped form { type = \"Bool\", value = <no_public_ip> }"
  }
}

run "vnet_injection_requires_all_inputs" {
  command = plan

  variables {
    virtual_network_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/net-rg/providers/Microsoft.Network/virtualNetworks/my-vnet"
  }

  expect_failures = [azapi_resource.this]
}

# --- Encryption prep booleans ---

run "prepare_encryption_sent_when_cmk_enabled" {
  command = plan

  variables {
    customer_managed_key_enabled = true
  }

  assert {
    condition     = azapi_resource.this.body.properties.parameters.prepareEncryption.value == true
    error_message = "customer_managed_key_enabled must map to parameters.prepareEncryption = { type = \"Bool\", value = true }"
  }
}

run "prepare_encryption_always_present_with_real_value" {
  command = plan

  # azurerm sent these unconditionally; the managed-app appliance expects them
  # (a body without them failed live with InvalidApplicationDefinition).
  assert {
    condition     = azapi_resource.this.body.properties.parameters.prepareEncryption.type == "Bool" && azapi_resource.this.body.properties.parameters.prepareEncryption.value == false && azapi_resource.this.body.properties.parameters.requireInfrastructureEncryption.value == false
    error_message = "prepareEncryption / requireInfrastructureEncryption must always be present with their real value, even when false"
  }
}

run "infrastructure_encryption_sent_when_enabled" {
  command = plan

  variables {
    infrastructure_encryption_enabled = true
  }

  assert {
    condition     = azapi_resource.this.body.properties.parameters.requireInfrastructureEncryption.value == true
    error_message = "infrastructure_encryption_enabled must map to parameters.requireInfrastructureEncryption = { type = \"Bool\", value = true }"
  }
}

# --- CMK key-id parsing into ARM keyVaultProperties ---

run "managed_services_cmk_parsed_into_key_vault_properties" {
  command = plan

  variables {
    customer_managed_key_enabled          = true
    managed_services_cmk_key_vault_key_id = "https://my-kv.vault.azure.net/keys/my-key/abc123"
  }

  assert {
    condition     = azapi_resource.this.body.properties.encryption.entities.managedServices.keySource == "Microsoft.Keyvault" && azapi_resource.this.body.properties.encryption.entities.managedServices.keyVaultProperties.keyName == "my-key" && azapi_resource.this.body.properties.encryption.entities.managedServices.keyVaultProperties.keyVaultUri == "https://my-kv.vault.azure.net" && azapi_resource.this.body.properties.encryption.entities.managedServices.keyVaultProperties.keyVersion == "abc123"
    error_message = "managed services key id must be split into keyName / keyVaultUri / keyVersion"
  }
}

run "managed_disk_cmk_parsed_with_rotation" {
  command = plan

  variables {
    managed_disk_cmk_key_vault_key_id                   = "https://my-kv.vault.azure.net/keys/disk-key/def456"
    managed_disk_cmk_rotation_to_latest_version_enabled = true
  }

  assert {
    condition     = azapi_resource.this.body.properties.encryption.entities.managedDisk.keyVaultProperties.keyName == "disk-key" && azapi_resource.this.body.properties.encryption.entities.managedDisk.rotationToLatestKeyVersionEnabled == true
    error_message = "managed disk key id must be split into keyVaultProperties and carry rotationToLatestKeyVersionEnabled"
  }
}

run "encryption_block_omitted_without_keys" {
  command = plan

  assert {
    condition     = azapi_resource.this.body.properties.encryption == null
    error_message = "the encryption entities block must be null (stripped from the request payload) when no key is supplied"
  }
}

# --- Network access ---

run "public_network_access_disabled_maps_to_arm_enum" {
  command = plan

  variables {
    public_network_access_enabled = false
  }

  assert {
    condition     = azapi_resource.this.body.properties.publicNetworkAccess == "Disabled"
    error_message = "public_network_access_enabled = false must map to publicNetworkAccess = \"Disabled\""
  }
}

run "nsg_rules_passthrough" {
  command = plan

  variables {
    network_security_group_rules_required = "NoAzureDatabricksRules"
  }

  assert {
    condition     = azapi_resource.this.body.properties.requiredNsgRules == "NoAzureDatabricksRules"
    error_message = "network_security_group_rules_required should pass through to requiredNsgRules unchanged"
  }
}

run "nsg_rules_omitted_when_null" {
  command = plan

  assert {
    condition     = azapi_resource.this.body.properties.requiredNsgRules == null
    error_message = "requiredNsgRules must be null (stripped from the request payload; ARM default AllRules) when the variable is null"
  }
}

# --- Enhanced security and compliance ---

run "esc_block_omitted_when_all_off" {
  command = plan

  assert {
    condition     = azapi_resource.this.body.properties.enhancedSecurityCompliance == null
    error_message = "enhancedSecurityCompliance must be null (stripped from the request payload) when ESM, ACU and CSP are all off"
  }
}

run "esc_block_values_map_to_arm_enums" {
  command = plan

  variables {
    enhanced_security_monitoring_enabled = true
    automatic_cluster_update_enabled     = false
  }

  assert {
    condition     = azapi_resource.this.body.properties.enhancedSecurityCompliance.enhancedSecurityMonitoring.value == "Enabled" && azapi_resource.this.body.properties.enhancedSecurityCompliance.automaticClusterUpdate.value == "Disabled" && azapi_resource.this.body.properties.enhancedSecurityCompliance.complianceSecurityProfile.value == "Disabled"
    error_message = "ESC flags must map to Enabled/Disabled ARM enum values with the off-flags explicit"
  }
}

run "csp_carries_standards" {
  command = plan

  variables {
    compliance_security_profile_enabled   = true
    compliance_security_profile_standards = ["HIPAA"]
    enhanced_security_monitoring_enabled  = true
    automatic_cluster_update_enabled      = true
  }

  assert {
    condition     = azapi_resource.this.body.properties.enhancedSecurityCompliance.complianceSecurityProfile.value == "Enabled" && contains(azapi_resource.this.body.properties.enhancedSecurityCompliance.complianceSecurityProfile.complianceStandards, "HIPAA")
    error_message = "compliance_security_profile_standards must ride in complianceSecurityProfile.complianceStandards"
  }
}

run "csp_requires_esm_and_acu" {
  command = plan

  variables {
    compliance_security_profile_enabled = true
  }

  expect_failures = [azapi_resource.this]
}

run "cmk_features_require_premium" {
  command = plan

  variables {
    sku                          = "standard"
    customer_managed_key_enabled = true
  }

  expect_failures = [azapi_resource.this]
}

run "managed_services_cmk_requires_customer_managed_key_enabled" {
  command = plan

  variables {
    managed_services_cmk_key_vault_key_id = "https://my-kv.vault.azure.net/keys/my-key/abc123"
  }

  expect_failures = [azapi_resource.this]
}

# --- Default storage firewall ---

run "storage_firewall_sends_connector_and_enum" {
  command = plan

  variables {
    default_storage_firewall_enabled = true
    access_connector_id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Databricks/accessConnectors/my-connector"
  }

  assert {
    condition     = azapi_resource.this.body.properties.defaultStorageFirewall == "Enabled" && azapi_resource.this.body.properties.accessConnector.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Databricks/accessConnectors/my-connector" && azapi_resource.this.body.properties.accessConnector.identityType == "SystemAssigned"
    error_message = "default_storage_firewall_enabled must set defaultStorageFirewall = \"Enabled\" plus the accessConnector block"
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
    compliance_security_profile_enabled  = true
    enhanced_security_monitoring_enabled = true
    automatic_cluster_update_enabled     = true
    extended_compliance_standards        = ["HITRUST"]
  }

  assert {
    condition     = local.azapi_compliance_needed == true
    error_message = "azapi_compliance_needed should be true when extended_compliance_standards is non-empty and CSP is on"
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
    enhanced_security_monitoring_enabled  = true
    automatic_cluster_update_enabled      = true
  }

  assert {
    condition     = contains(local.all_compliance_standards, "HIPAA") && contains(local.all_compliance_standards, "HITRUST")
    error_message = "all_compliance_standards should contain both azurerm and extended standards"
  }

  assert {
    condition     = length(azapi_update_resource.compliance_standards) == 1
    error_message = "azapi_update_resource should be created when extended standards are requested"
  }
}

# --- Outputs ---

run "workspace_url_has_https_prefix" {
  command = plan

  assert {
    condition     = startswith(output.workspace_url, "https://")
    error_message = "workspace_url output should start with https://"
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
    compliance_security_profile_standards = ["HITRUST"]
  }

  expect_failures = [var.compliance_security_profile_standards]
}

run "invalid_extended_standard_rejected" {
  command = plan

  variables {
    extended_compliance_standards = ["INVALID_STANDARD"]
  }

  expect_failures = [var.extended_compliance_standards]
}

run "unversioned_cmk_key_rejected" {
  command = plan

  variables {
    customer_managed_key_enabled          = true
    managed_services_cmk_key_vault_key_id = "https://my-kv.vault.azure.net/keys/my-key"
  }

  expect_failures = [var.managed_services_cmk_key_vault_key_id]
}

run "invalid_access_connector_identity_type_rejected" {
  command = plan

  variables {
    default_storage_firewall_enabled = true
    access_connector_identity_type   = "Wrong"
  }

  expect_failures = [var.access_connector_identity_type]
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

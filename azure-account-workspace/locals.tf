locals {
  # VNet injection is active when virtual_network_id is provided.
  vnet_injection_enabled = var.virtual_network_id != null

  # Extended compliance standards (beyond HIPAA/PCI_DSS/NONE) require an azapi
  # post-creation update. The combined list merges both sets.
  all_compliance_standards = distinct(concat(
    var.compliance_security_profile_standards,
    var.extended_compliance_standards,
  ))

  # The azapi workaround is needed when extended standards are requested.
  azapi_compliance_needed = var.compliance_security_profile_enabled && length(var.extended_compliance_standards) > 0

  # Root DBFS CMK post-creation resource is created only when a key is supplied.
  root_dbfs_cmk_enabled = var.root_dbfs_cmk_key_vault_key_id != null

  # ESC block is sent when any of the three add-on flags is on (azurerm's
  # dynamic-block condition, carried over).
  esc_needed = (
    var.compliance_security_profile_enabled ||
    var.enhanced_security_monitoring_enabled ||
    var.automatic_cluster_update_enabled
  )

  # Managed resource group: ARM wants the full resource-group ID. Default name
  # mirrors the azurerm provider's fallback (databricks-rg-<parent-rg-name>).
  subscription_scope         = join("/", slice(split("/", var.resource_group_id), 0, 3))
  parent_resource_group_name = element(split("/", var.resource_group_id), 4)
  managed_resource_group_id  = "${local.subscription_scope}/resourceGroups/${coalesce(var.managed_resource_group_name, "databricks-rg-${local.parent_resource_group_name}")}"

  # Key-id parsing: azurerm required a VERSIONED key id and split it into
  # vault / name / version for the ARM body; same contract here. The regexes
  # tolerate any Key Vault domain (public cloud, gov, etc.).
  managed_services_cmk = var.managed_services_cmk_key_vault_key_id != null ? regex("^https://([^/]+)/keys/([^/]+)/([^/]+)$", var.managed_services_cmk_key_vault_key_id) : null
  managed_disk_cmk     = var.managed_disk_cmk_key_vault_key_id != null ? regex("^https://([^/]+)/keys/([^/]+)/([^/]+)$", var.managed_disk_cmk_key_vault_key_id) : null

  # ARM WorkspaceCustomParameters — every entry is a wrapped {type, value}
  # object. prepareEncryption / requireInfrastructureEncryption are ALWAYS sent
  # with their real value (azurerm's expand sent them unconditionally; a body
  # without them failed live with InvalidApplicationDefinition 2026-10-30 —
  # the managed-app appliance behind the workspace expects them present).
  # Null VNet entries are stripped from the payload by ignore_null_property.
  # NOTE: deliberately NO `? {...} : {}`
  # conditionals or merge() here — unifying an object literal with the empty
  # object makes HCL collapse the values to map(string), silently stringifying
  # the enableNoPublicIp boolean.
  parameters = {
    customVirtualNetworkId          = local.vnet_injection_enabled ? { type = "String", value = var.virtual_network_id } : null
    customPublicSubnetName          = local.vnet_injection_enabled ? { type = "String", value = var.host_subnet_name } : null
    customPrivateSubnetName         = local.vnet_injection_enabled ? { type = "String", value = var.container_subnet_name } : null
    enableNoPublicIp                = local.vnet_injection_enabled ? { type = "Bool", value = var.no_public_ip } : null
    prepareEncryption               = { type = "Bool", value = var.customer_managed_key_enabled }
    requireInfrastructureEncryption = { type = "Bool", value = var.infrastructure_encryption_enabled }
  }

  # Workspace-level encryption entities, built only from the two key-id
  # variables — exactly the fields azurerm's expand used.
  encryption_entities = (local.managed_services_cmk != null || local.managed_disk_cmk != null) ? {
    managedServices = local.managed_services_cmk != null ? {
      keySource = "Microsoft.Keyvault"
      keyVaultProperties = {
        keyName     = local.managed_services_cmk[1],
        keyVaultUri = "https://${local.managed_services_cmk[0]}",
        keyVersion  = local.managed_services_cmk[2],
      },
    } : null
    managedDisk = local.managed_disk_cmk != null ? {
      keySource = "Microsoft.Keyvault"
      keyVaultProperties = {
        keyName     = local.managed_disk_cmk[1],
        keyVaultUri = "https://${local.managed_disk_cmk[0]}",
        keyVersion  = local.managed_disk_cmk[2],
      }
      rotationToLatestKeyVersionEnabled = var.managed_disk_cmk_rotation_to_latest_version_enabled,
    } : null
  } : null
}

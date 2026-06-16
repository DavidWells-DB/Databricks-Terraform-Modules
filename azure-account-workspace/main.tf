resource "azurerm_databricks_workspace" "this" {
  #checkov:skip=CKV_AZURE_158: Private link is optional — callers configure public_network_access_enabled=false and VNet injection when required.
  #checkov:skip=CKV2_AZURE_48: Root DBFS CMK is optional — callers set root_dbfs_cmk_key_vault_key_id when required. Azure Gov/IL5 requires CMK.
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  tags                = var.tags

  managed_resource_group_name = var.managed_resource_group_name

  customer_managed_key_enabled          = var.customer_managed_key_enabled
  infrastructure_encryption_enabled     = var.infrastructure_encryption_enabled
  managed_services_cmk_key_vault_key_id = var.managed_services_cmk_key_vault_key_id
  public_network_access_enabled         = var.public_network_access_enabled
  network_security_group_rules_required = var.network_security_group_rules_required

  # managed_disk_cmk_key_vault_key_id and managed_disk_cmk_rotation_to_latest_version_enabled
  # must be specified together per the azurerm provider schema constraint — only set both
  # when a disk CMK key is provided.
  managed_disk_cmk_key_vault_key_id                   = var.managed_disk_cmk_key_vault_key_id
  managed_disk_cmk_rotation_to_latest_version_enabled = var.managed_disk_cmk_key_vault_key_id != null ? var.managed_disk_cmk_rotation_to_latest_version_enabled : null

  # default_storage_firewall_enabled and access_connector_id must be specified together
  # per the azurerm provider schema constraint — only set both when the firewall is enabled.
  default_storage_firewall_enabled = var.default_storage_firewall_enabled ? true : null
  access_connector_id              = var.default_storage_firewall_enabled ? var.access_connector_id : null

  dynamic "custom_parameters" {
    for_each = local.vnet_injection_enabled ? [1] : []
    content {
      virtual_network_id                                   = var.virtual_network_id
      public_subnet_name                                   = var.host_subnet_name
      private_subnet_name                                  = var.container_subnet_name
      public_subnet_network_security_group_association_id  = var.public_subnet_network_security_group_association_id
      private_subnet_network_security_group_association_id = var.private_subnet_network_security_group_association_id
      no_public_ip                                         = var.no_public_ip
    }
  }

  dynamic "enhanced_security_compliance" {
    for_each = (
      var.compliance_security_profile_enabled ||
      var.enhanced_security_monitoring_enabled ||
      var.automatic_cluster_update_enabled
    ) ? [1] : []
    content {
      automatic_cluster_update_enabled      = var.automatic_cluster_update_enabled
      compliance_security_profile_enabled   = var.compliance_security_profile_enabled
      compliance_security_profile_standards = var.compliance_security_profile_standards
      enhanced_security_monitoring_enabled  = var.enhanced_security_monitoring_enabled
    }
  }

  lifecycle {
    # compliance_security_profile_standards can be extended via azapi_update_resource
    # (see below) for standards outside the azurerm allowlist. Ignoring changes prevents
    # the azurerm provider from reverting standards written by azapi. Per DATABRICKS_RULES Rule 3.2.
    ignore_changes = [
      enhanced_security_compliance[0].compliance_security_profile_standards,
    ]
  }
}

# Root DBFS customer-managed key — applied as a post-creation step because the
# workspace must exist before the CMK association can be registered.
resource "azurerm_databricks_workspace_root_dbfs_customer_managed_key" "this" {
  count = local.root_dbfs_cmk_enabled ? 1 : 0

  workspace_id     = azurerm_databricks_workspace.this.id
  key_vault_key_id = var.root_dbfs_cmk_key_vault_key_id
  key_vault_id     = var.root_dbfs_cmk_key_vault_id
}

# Extended compliance standards (HITRUST, IRAP_PROTECTED, UK_CYBER_ESSENTIALS_PLUS,
# CANADA_PROTECTED_B) are not supported by the azurerm provider and must be applied
# via the ARM REST API. azapi_update_resource patches the workspace in-place without
# replacing it. Per MODULE_CANDIDATES notes and DATABRICKS_RULES Rule 3.2: ignore_changes
# on the azurerm workspace prevents the azurerm provider from reverting standards written here.
resource "azapi_update_resource" "compliance_standards" {
  count = local.azapi_compliance_needed ? 1 : 0

  type        = "Microsoft.Databricks/workspaces@2023-09-15-preview"
  resource_id = azurerm_databricks_workspace.this.id

  body = {
    properties = {
      enhancedSecurityCompliance = {
        complianceSecurityProfile = {
          value               = "Enabled"
          complianceStandards = local.all_compliance_standards
        }
      }
    }
  }

  depends_on = [azurerm_databricks_workspace.this]
}

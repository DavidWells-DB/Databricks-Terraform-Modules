resource "azurerm_databricks_workspace" "this" {
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

  # azurerm requires managed_disk_cmk_key_vault_key_id and
  # managed_disk_cmk_rotation_to_latest_version_enabled to be set together.
  managed_disk_cmk_key_vault_key_id                   = var.managed_disk_cmk_key_vault_key_id
  managed_disk_cmk_rotation_to_latest_version_enabled = var.managed_disk_cmk_key_vault_key_id != null ? var.managed_disk_cmk_rotation_to_latest_version_enabled : null

  # azurerm requires default_storage_firewall_enabled and access_connector_id to be
  # specified together. Only set both when the firewall is enabled; omit otherwise.
  default_storage_firewall_enabled = var.access_connector_id != null ? var.default_storage_firewall_enabled : null
  access_connector_id              = var.access_connector_id

  # No custom_parameters block: serverless workspaces do not use VNet injection.
  # Omitting custom_parameters is the Azure Databricks serverless pattern.
}

# Root DBFS customer-managed key — applied as a post-creation step because the
# workspace must exist before the CMK association can be registered.
resource "azurerm_databricks_workspace_root_dbfs_customer_managed_key" "this" {
  count = local.root_dbfs_cmk_enabled ? 1 : 0

  workspace_id     = azurerm_databricks_workspace.this.id
  key_vault_key_id = var.root_dbfs_cmk_key_vault_key_id
  key_vault_id     = var.root_dbfs_cmk_key_vault_id
}

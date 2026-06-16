output "key_vault_id" {
  description = "Resource ID of the Azure Key Vault. Pass to azurerm_databricks_workspace as managed_services_cmk_key_vault_id and managed_disk_cmk_key_vault_id."
  value       = azurerm_key_vault.this.id
}

output "key_vault_name" {
  description = "Name of the Azure Key Vault."
  value       = azurerm_key_vault.this.name
}

output "key_vault_uri" {
  description = "URI of the Azure Key Vault (e.g. https://<name>.vault.azure.net/). Used to construct key version URLs."
  value       = azurerm_key_vault.this.vault_uri
}

output "managed_services_key_id" {
  description = "Versioned resource ID of the managed-services CMK. Pass to azurerm_databricks_workspace as managed_services_cmk_key_vault_key_id."
  value       = azurerm_key_vault_key.managed_services.id
}

output "managed_services_key_versionless_id" {
  description = "Versionless resource ID of the managed-services CMK. Useful for callers that need to reference the key without pinning to a specific version."
  value       = azurerm_key_vault_key.managed_services.versionless_id
}

output "workspace_storage_key_id" {
  description = "Versioned resource ID of the workspace-storage CMK (DBFS root). Pass to azurerm_databricks_workspace_root_dbfs_customer_managed_key."
  value       = azurerm_key_vault_key.workspace_storage.id
}

output "workspace_storage_key_versionless_id" {
  description = "Versionless resource ID of the workspace-storage CMK. Useful for callers that need to reference the key without pinning to a specific version."
  value       = azurerm_key_vault_key.workspace_storage.versionless_id
}

output "managed_disk_key_id" {
  description = "Versioned resource ID of the managed-disk CMK. Pass to azurerm_databricks_workspace as managed_disk_cmk_key_vault_key_id."
  value       = azurerm_key_vault_key.managed_disk.id
}

output "managed_disk_key_versionless_id" {
  description = "Versionless resource ID of the managed-disk CMK. Useful for callers that need to reference the key without pinning to a specific version."
  value       = azurerm_key_vault_key.managed_disk.versionless_id
}

output "private_endpoint_id" {
  description = "Resource ID of the Key Vault private endpoint. Null when private_endpoint input is not set."
  value       = var.private_endpoint != null ? azurerm_private_endpoint.key_vault[0].id : null
}

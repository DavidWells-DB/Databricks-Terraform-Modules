output "storage_account_name" {
  description = "Name of the ADLS Gen2 storage account. Pass to a Unity Catalog metastore or workspace module as the storage account identifier."
  value       = azurerm_storage_account.this.name
}

output "storage_account_id" {
  description = "Azure resource ID of the storage account. Used for RBAC role assignments (e.g. granting the Access Connector Storage Blob Data Contributor)."
  value       = azurerm_storage_account.this.id
}

output "container_name" {
  description = "Name of the ADLS Gen2 container (filesystem) created inside the storage account."
  value       = azurerm_storage_container.this.name
}

output "dfs_endpoint" {
  description = "Primary DFS (Data Lake Storage Gen2) endpoint URL for the storage account. Used as the external location path in Unity Catalog."
  value       = azurerm_storage_account.this.primary_dfs_endpoint
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint URL for the storage account. Useful for constructing abfss:// paths."
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "storage_account_principal_id" {
  description = "Object ID of the storage account's system-assigned managed identity. Populated only when kms_key_id is set (CMK mode). Null otherwise."
  value       = local.use_cmk ? azurerm_storage_account.this.identity[0].principal_id : null
}

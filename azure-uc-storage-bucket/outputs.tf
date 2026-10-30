output "storage_account_id" {
  description = "ARM resource ID of the dedicated ADLS Gen2 storage account. Feed to azure-uc-storage-credential's storage_account_id."
  value       = azurerm_storage_account.this.id
}

output "storage_account_name" {
  description = "Name of the dedicated ADLS Gen2 storage account."
  value       = azurerm_storage_account.this.name
}

output "container_name" {
  description = "Name of the dedicated container for the catalog's managed data."
  value       = azurerm_storage_container.this.name
}

output "storage_root" {
  description = "The Unity Catalog storage-root URL (abfss://<container>@<account>.dfs.core.windows.net). Append the catalog's path suffix at the composition."
  value       = "abfss://${azurerm_storage_container.this.name}@${azurerm_storage_account.this.name}.dfs.core.windows.net"
}

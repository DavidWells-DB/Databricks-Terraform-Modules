output "access_connector_id" {
  description = "Full Azure resource ID of the Databricks Access Connector. Pass to other modules or external locations that reference this credential."
  value       = azurerm_databricks_access_connector.this.id
}

output "access_connector_principal_id" {
  description = "Object ID of the Access Connector's SystemAssigned managed identity. Useful for constructing additional Azure role assignments."
  value       = azurerm_databricks_access_connector.this.identity[0].principal_id
}

output "storage_credential_id" {
  description = "Databricks Unity Catalog storage credential ID. Pass to databricks_external_location or other UC resources that require a storage credential."
  value       = databricks_storage_credential.this.id
}

output "storage_credential_name" {
  description = "Name of the Databricks Unity Catalog storage credential, as registered."
  value       = databricks_storage_credential.this.name
}

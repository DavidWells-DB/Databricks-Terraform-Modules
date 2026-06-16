output "credentials_id" {
  description = "Databricks credentials ID"
  value       = databricks_mws_credentials.this.credentials_id
}

output "storage_configuration_id" {
  description = "Databricks storage configuration ID"
  value       = databricks_mws_storage_configurations.this.storage_configuration_id
}

output "databricks_network_id" {
  description = "Databricks network configuration ID"
  value       = databricks_mws_networks.this.network_id
}

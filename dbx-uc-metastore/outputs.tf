output "metastore_id" {
  description = "The globally unique ID of the Unity Catalog metastore. Pass to workspace assignment modules as the metastore_id input."
  value       = databricks_metastore.this.id
}

output "metastore_name" {
  description = "Display name of the Unity Catalog metastore."
  value       = databricks_metastore.this.name
}

output "data_access_id" {
  description = "ID of the databricks_metastore_data_access resource in format <metastore_id>|<name>, or null for a storageless metastore. Useful for verification and downstream references."
  value       = try(databricks_metastore_data_access.this[0].id, null)
}

output "assignment_ids" {
  description = "Map of assignment labels to metastore assignment IDs (format: <workspace_id>|<metastore_id>). Keys match the keys of var.workspace_ids."
  value       = { for k, v in databricks_metastore_assignment.this : k => v.id }
}

output "assigned_workspace_ids" {
  description = "Map of assignment labels to the numeric workspace IDs that were assigned the metastore. Mirrors var.workspace_ids; useful for downstream references."
  value       = { for k, v in databricks_metastore_assignment.this : k => v.workspace_id }
}

output "metastore_id" {
  description = "ID of the metastore that was assigned. Echoed from input for use in downstream module compositions."
  value       = var.metastore_id
}

output "default_catalog_name" {
  description = "Default catalog name configured via databricks_default_namespace_setting, or null if not set."
  value       = var.default_catalog_name
}

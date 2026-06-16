output "allow_list_id" {
  description = "Databricks IP access list ID for the ALLOW list. Use this to reference the list in downstream tooling or for audit purposes."
  value       = databricks_ip_access_list.allow.id
}

output "allow_list_label" {
  description = "Label of the ALLOW IP access list as registered in Databricks."
  value       = databricks_ip_access_list.allow.label
}

output "block_list_id" {
  description = "Databricks IP access list ID for the BLOCK list. null when no block list was configured."
  value       = length(databricks_ip_access_list.block) > 0 ? databricks_ip_access_list.block[0].id : null
}

output "workspace_conf_id" {
  description = "ID of the databricks_workspace_conf resource that enabled IP access list enforcement. Useful for expressing explicit dependencies in consuming configurations."
  value       = databricks_workspace_conf.this.id
}

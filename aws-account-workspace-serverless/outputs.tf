output "workspace_id" {
  description = "Databricks workspace ID. Use as input to workspace-scoped modules and the workspace provider's workspace_id."
  value       = databricks_mws_workspaces.this.workspace_id
}

output "workspace_url" {
  description = "Full HTTPS URL of the workspace (e.g. https://my-ws.cloud.databricks.com). Use as the host for the workspace-scoped Databricks provider."
  value       = databricks_mws_workspaces.this.workspace_url
}

output "workspace_host" {
  description = "Workspace URL without trailing slash — identical to workspace_url. Provided as a convenience alias for provider host arguments."
  value       = databricks_mws_workspaces.this.workspace_url
}

output "workspace_status" {
  description = "Current provisioning status of the workspace (e.g. RUNNING, PROVISIONING, FAILED). Useful for debugging and downstream conditional logic."
  value       = databricks_mws_workspaces.this.workspace_status
}

output "workspace_status_message" {
  description = "Human-readable message accompanying workspace_status. Populated on error to aid diagnosis."
  value       = databricks_mws_workspaces.this.workspace_status_message
}

output "databricks_account_host" {
  description = "Databricks account console host URL computed from databricks_gov_shard. Useful for configuring the account provider in the root composition."
  value       = local.databricks_account_host
}

output "ncc_binding_id" {
  description = "ID of the NCC binding resource, or null if no network_connectivity_config_id was provided."
  value       = length(databricks_mws_ncc_binding.this) > 0 ? databricks_mws_ncc_binding.this[0].id : null
}

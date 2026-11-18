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

# (ncc_binding_id output removed in v0.5.0 — the binding is owned by
#  dbx-workspace-network-serverless; consume its ncc_binding_id output there.)

output "compute_mode" {
  description = "The deployed workspace compute mode (\"SERVERLESS\"), refreshed from the account API on every plan/apply. Lets consumers assert the deployed workspace type — a value other than SERVERLESS here would mean the workspace is not what this module promises."
  value       = databricks_mws_workspaces.this.compute_mode
}

output "managed_services_key_id" {
  description = "Managed-services key configuration ID applied by post-create update, or null."
  value       = databricks_mws_workspaces.this.managed_services_customer_managed_key_id
}

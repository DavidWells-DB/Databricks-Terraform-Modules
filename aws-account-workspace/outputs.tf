output "workspace_id" {
  description = "Databricks workspace ID (numeric). Used by workspace-scoped modules and data sources that require a workspace ID."
  value       = databricks_mws_workspaces.this.workspace_id
}

output "workspace_url" {
  description = "Full URL of the Databricks workspace (e.g. https://adb-<id>.azuredatabricks.net). Use as the host for the workspace-scoped Databricks provider after DNS propagation."
  value       = databricks_mws_workspaces.this.workspace_url
}

output "workspace_host" {
  description = "Alias for workspace_url. Provided for callers that prefer the 'host' naming convention when configuring the workspace Databricks provider."
  value       = databricks_mws_workspaces.this.workspace_url
}

output "deployment_name" {
  description = "Deployment name portion of the workspace URL subdomain. Useful for constructing workspace-specific resource names."
  value       = databricks_mws_workspaces.this.deployment_name
}

output "dns_propagation_complete" {
  description = "Opaque value that becomes available only after the DNS propagation sleep completes. Use this output as an implicit depends_on trigger in root compositions that configure workspace-scoped providers."
  value       = time_sleep.dns_propagation.id
}

output "databricks_host" {
  description = "Databricks account host URL computed from databricks_gov_shard. Useful for verification and for configuring downstream provider instances."
  value       = local.databricks_host
}

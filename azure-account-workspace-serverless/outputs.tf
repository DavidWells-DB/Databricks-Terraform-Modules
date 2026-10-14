output "workspace_id" {
  description = "Databricks workspace ID (numeric string). Used as the identifier within the Databricks control plane."
  value       = azapi_resource.this.output.workspace_id
}

output "workspace_url" {
  description = "Workspace URL in the format https://adb-{id}.{n}.azuredatabricks.net. Use as the host for the workspace-scoped Databricks provider."
  value       = "https://${azapi_resource.this.output.workspace_url}"
}

output "workspace_resource_id" {
  description = "Azure Resource Manager resource ID of the Databricks workspace. Used for RBAC assignments, policy, and diagnostic settings."
  value       = azapi_resource.this.id
}

output "compute_mode" {
  description = "The deployed ARM properties.computeMode (\"Serverless\"). Lets consumers assert the workspace type — the exact check that would have caught the v0.1.0 bug (a Classic managed-VNet workspace masquerading as serverless)."
  value       = azapi_resource.this.output.compute_mode
}

output "binding_id" {
  description = "Composite binding identifier in the format <workspace_id>|<network_policy_id>. The databricks_workspace_network_option resource exports no id, so this is synthesized for referencing the binding in downstream tooling or expressing explicit dependencies."
  value       = "${databricks_workspace_network_option.this.workspace_id}|${databricks_workspace_network_option.this.network_policy_id}"
}

output "workspace_id" {
  description = "Workspace ID the network policy is bound to. Echoed for convenience when chaining module outputs."
  value       = databricks_workspace_network_option.this.workspace_id
}

output "network_policy_id" {
  description = "Network policy ID bound to the workspace. Echoed for convenience when chaining module outputs."
  value       = databricks_workspace_network_option.this.network_policy_id
}

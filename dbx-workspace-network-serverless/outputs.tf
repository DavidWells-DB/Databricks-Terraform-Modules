output "ncc_binding_id" {
  description = "Composite identifier of the NCC binding in the format <network_connectivity_config_id>|<workspace_id>. Useful for referencing the binding in downstream resources."
  value       = databricks_mws_ncc_binding.this.id
}

output "network_connectivity_config_id" {
  description = "Network Connectivity Config ID that is bound to the workspace. Echoed for convenience when building downstream configurations."
  value       = databricks_mws_ncc_binding.this.network_connectivity_config_id
}

output "workspace_id" {
  description = "Workspace ID that the NCC is bound to. Echoed for convenience when chaining module outputs."
  value       = databricks_mws_ncc_binding.this.workspace_id
}

output "private_endpoint_rule_ids" {
  description = "Map of private endpoint rule IDs keyed by the rule key input. Empty map when no rules are configured."
  value       = { for k, r in databricks_mws_ncc_private_endpoint_rule.this : k => r.rule_id }
}

output "network_policy_id" {
  description = "Network policy ID assigned to the workspace. Null when network_policy_id was not provided and databricks_workspace_network_option was not created."
  value       = var.network_policy_id != null ? databricks_workspace_network_option.this[0].network_policy_id : null
}

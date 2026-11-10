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

# (network_policy_id output removed in v0.3.0 — the policy binding is owned by
#  dbx-workspace-network-policy-binding; consume its outputs there.)

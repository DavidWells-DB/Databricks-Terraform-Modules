output "network_connectivity_config_id" {
  description = "The NCC ID. Pass to dbx-workspace-network-serverless (the binding + private-endpoint-rule owner)."
  value       = module.ncc.network_connectivity_config_id
}

output "network_policy_id" {
  description = "The account network policy ID, or null when create_policy = false. Pass to dbx-workspace-network-policy-binding (the binding owner)."
  value       = var.create_policy ? module.policy[0].network_policy_id : null
}

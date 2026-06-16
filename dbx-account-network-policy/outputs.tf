output "network_policy_id" {
  description = "Databricks account-level network policy ID. Pass to workspace or serverless compute configuration as the network_policy_id input."
  value       = databricks_account_network_policy.this.network_policy_id
}

output "policy_name" {
  description = "Name of the network policy."
  value       = databricks_account_network_policy.this.network_policy_id
}

output "egress_mode" {
  description = "Egress restriction mode configured for the policy (ALLOW_LIST or UNRESTRICTED)."
  value       = databricks_account_network_policy.this.egress.network_access.restriction_mode
}

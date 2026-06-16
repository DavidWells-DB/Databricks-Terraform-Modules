output "network_connectivity_config_id" {
  description = "Databricks Network Connectivity Config ID. Pass to databricks_mws_ncc_binding to attach this NCC to a workspace, or to databricks_mws_workspaces for direct association."
  value       = databricks_mws_network_connectivity_config.this.network_connectivity_config_id
}

output "ncc_name" {
  description = "Name of the Network Connectivity Config as registered in Databricks."
  value       = databricks_mws_network_connectivity_config.this.name
}

output "region" {
  description = "Azure region of the Network Connectivity Config."
  value       = databricks_mws_network_connectivity_config.this.region
}

output "network_policy_id" {
  description = "ID of the account network policy, or null when no policy was created (allowed_internet_destinations was not set)."
  value       = var.allowed_internet_destinations != null ? databricks_account_network_policy.this[0].network_policy_id : null
}

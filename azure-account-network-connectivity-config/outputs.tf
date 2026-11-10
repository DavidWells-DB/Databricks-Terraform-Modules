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

# (network_policy_id output removed in v0.2.0 — the policy is owned by
#  dbx-account-network-policy / azure-account-network-foundation.)

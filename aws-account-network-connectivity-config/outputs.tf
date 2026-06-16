output "network_connectivity_config_id" {
  description = "Databricks Network Connectivity Configuration ID. Pass to workspace binding modules (databricks_mws_ncc_binding) as the network_connectivity_config_id input."
  value       = databricks_mws_network_connectivity_config.this.network_connectivity_config_id
}

output "name" {
  description = "Name of the Network Connectivity Configuration as registered in Databricks."
  value       = databricks_mws_network_connectivity_config.this.name
}

output "region" {
  description = "AWS region of the Network Connectivity Configuration. Only workspaces in this region can reference this NCC."
  value       = databricks_mws_network_connectivity_config.this.region
}

output "creation_time" {
  description = "Epoch milliseconds timestamp when the NCC was created. Useful for auditing and ordering."
  value       = databricks_mws_network_connectivity_config.this.creation_time
}

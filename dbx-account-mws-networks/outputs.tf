output "databricks_network_id" {
  description = "Databricks network configuration ID the workspace should use: the PrivateLink registration when enable_privatelink is set, otherwise the base registration. Pass to workspace creation modules as their network_id input."
  value       = databricks_mws_networks.this[local.active_network].network_id
}

output "network_ids" {
  description = "Map of network config role (base / privatelink) to Databricks network ID. When PrivateLink is enabled both exist; the 'base' entry is the retained, now-detached config left behind by the in-place cutover. It is harmless (metadata-only, no documented account limit); delete it deliberately later if you want to tidy up — safe once no workspace references it."
  value       = { for k, n in databricks_mws_networks.this : k => n.network_id }
}

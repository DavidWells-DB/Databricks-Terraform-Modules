output "local_peering_id" {
  description = "Azure resource ID of the local-to-remote VNet peering object."
  value       = azurerm_virtual_network_peering.local_to_remote.id
}

output "remote_peering_id" {
  description = "Azure resource ID of the remote-to-local VNet peering object."
  value       = azurerm_virtual_network_peering.remote_to_local.id
}

output "local_peering_name" {
  description = "Name of the local-to-remote VNet peering object (e.g. <local-vnet>-to-<remote-vnet>)."
  value       = azurerm_virtual_network_peering.local_to_remote.name
}

output "remote_peering_name" {
  description = "Name of the remote-to-local VNet peering object (e.g. <remote-vnet>-to-<local-vnet>)."
  value       = azurerm_virtual_network_peering.remote_to_local.name
}

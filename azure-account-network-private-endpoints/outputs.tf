output "private_dns_zone_id" {
  description = "Azure resource ID of the privatelink.azuredatabricks.net private DNS zone."
  value       = azurerm_private_dns_zone.this.id
}

output "private_dns_zone_name" {
  description = "Name of the private DNS zone (privatelink.azuredatabricks.net). Useful for additional VNet links added outside this module."
  value       = azurerm_private_dns_zone.this.name
}

output "back_end_pe_id" {
  description = "Azure resource ID of the back-end private endpoint (databricks_ui_api sub-resource). Always created."
  value       = azurerm_private_endpoint.this["back_end"].id
}

output "back_end_pe_private_ip" {
  description = "Private IP address allocated to the back-end private endpoint NIC. Useful for custom DNS or network ACL rules."
  value       = azurerm_private_endpoint.this["back_end"].private_service_connection[0].private_ip_address
}

output "front_end_pe_id" {
  description = "Azure resource ID of the front-end private endpoint. null when enable_front_end_pe is false."
  value       = var.enable_front_end_pe ? azurerm_private_endpoint.this["front_end"].id : null
}

output "front_end_pe_private_ip" {
  description = "Private IP address of the front-end private endpoint NIC. null when enable_front_end_pe is false."
  value       = var.enable_front_end_pe ? azurerm_private_endpoint.this["front_end"].private_service_connection[0].private_ip_address : null
}

output "browser_auth_pe_id" {
  description = "Azure resource ID of the browser_authentication private endpoint. null when enable_browser_auth_pe is false."
  value       = var.enable_browser_auth_pe ? azurerm_private_endpoint.this["browser_auth"].id : null
}

output "browser_auth_pe_private_ip" {
  description = "Private IP address of the browser_authentication private endpoint NIC. null when enable_browser_auth_pe is false."
  value       = var.enable_browser_auth_pe ? azurerm_private_endpoint.this["browser_auth"].private_service_connection[0].private_ip_address : null
}

output "dns_zone_virtual_network_link_ids" {
  description = "Map of DNS zone virtual network link names to their Azure resource IDs. Keys are 'spoke' and 'hub_<index>' for any hub VNets."
  value       = { for k, v in azurerm_private_dns_zone_virtual_network_link.this : k => v.id }
}

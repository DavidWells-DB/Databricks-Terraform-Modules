output "firewall_id" {
  description = "Resource ID of the Azure Firewall. Useful for cross-referencing in diagnostic settings, monitoring, or policy assignments."
  value       = azurerm_firewall.this.id
}

output "firewall_private_ip" {
  description = "Private IP address of the Azure Firewall front-end interface. Used as the next-hop in forced-tunnel routes and for verifying traffic flow."
  value       = azurerm_firewall.this.ip_configuration[0].private_ip_address
}

output "firewall_public_ip" {
  description = "Public IP address associated with the Azure Firewall. Required for allowlisting outbound traffic in external services or for auditing."
  value       = azurerm_public_ip.this.ip_address
}

output "firewall_public_ip_id" {
  description = "Resource ID of the public IP address associated with the Azure Firewall. Useful for DDoS protection plan association at the root composition."
  value       = azurerm_public_ip.this.id
}

output "firewall_policy_id" {
  description = "Resource ID of the Azure Firewall Policy. Pass to additional azurerm_firewall_policy_rule_collection_group resources that extend rule collections post-deployment."
  value       = azurerm_firewall_policy.this.id
}

output "route_table_id" {
  description = "Resource ID of the spoke route table containing the forced-tunnel (0.0.0.0/0 → firewall) route. The module associates this route table with each subnet in spoke_subnet_ids; expose here for cross-referencing."
  value       = azurerm_route_table.this.id
}

output "ip_group_id" {
  description = "Resource ID of the IP group representing spoke CIDR ranges. Useful for referencing in additional firewall policy rule collections that need to match on the same source addresses."
  value       = azurerm_ip_group.this.id
}

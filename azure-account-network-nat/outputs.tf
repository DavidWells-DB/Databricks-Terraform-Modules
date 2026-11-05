output "nat_gateway_id" {
  description = "Resource ID of the NAT gateway."
  value       = azurerm_nat_gateway.this.id
}

output "nat_gateway_name" {
  description = "Name of the NAT gateway."
  value       = azurerm_nat_gateway.this.name
}

output "public_ip_id" {
  description = "Resource ID of the public IP fronting the NAT gateway."
  value       = azurerm_public_ip.this.id
}

output "public_ip_address" {
  description = "The static public IP address egressing through the NAT gateway (useful for allow-listing on the destination side)."
  value       = azurerm_public_ip.this.ip_address
}

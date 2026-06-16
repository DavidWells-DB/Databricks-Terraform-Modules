output "vnet_id" {
  description = "Resource ID of the Azure Virtual Network. Pass to workspace creation modules and private endpoint modules as the vnet_id input."
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Name of the Azure Virtual Network."
  value       = azurerm_virtual_network.this.name
}

output "host_subnet_id" {
  description = "Resource ID of the Databricks host subnet. Pass to the workspace creation module's custom_parameters as the virtual_network_subnet_id."
  value       = azurerm_subnet.host.id
}

output "host_subnet_name" {
  description = "Name of the Databricks host subnet. Required by azurerm_databricks_workspace custom_parameters."
  value       = azurerm_subnet.host.name
}

output "container_subnet_id" {
  description = "Resource ID of the Databricks container subnet. Pass to the workspace creation module's custom_parameters as the private_subnet_network_security_group_association_id."
  value       = azurerm_subnet.container.id
}

output "container_subnet_name" {
  description = "Name of the Databricks container subnet. Required by azurerm_databricks_workspace custom_parameters."
  value       = azurerm_subnet.container.name
}

output "pe_subnet_id" {
  description = "Resource ID of the optional private endpoint subnet. Null when pe_subnet_name is not set."
  value       = local.create_pe_subnet ? azurerm_subnet.pe[0].id : null
}

output "nsg_id" {
  description = "Resource ID of the Network Security Group associated with the Databricks subnets. Useful for additional rule management or cross-referencing."
  value       = azurerm_network_security_group.this.id
}

output "nsg_name" {
  description = "Name of the Network Security Group associated with the Databricks subnets."
  value       = azurerm_network_security_group.this.name
}

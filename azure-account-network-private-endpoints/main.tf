# Private DNS zone for Azure Databricks private link.
# All Databricks workspace hostnames resolve via privatelink.azuredatabricks.net.
resource "azurerm_private_dns_zone" "this" {
  name                = "privatelink.azuredatabricks.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Link the private DNS zone to the spoke VNet and any hub VNets.
# registration_enabled = false because Databricks private link DNS records are managed
# by the private endpoint, not by VM auto-registration.
resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = local.all_vnet_links

  name                  = each.value.name
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this.name
  virtual_network_id    = each.value.vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

# Private endpoints: back-end is always created; front-end and browser_auth are conditional.
# Each endpoint registers a DNS A record into the private DNS zone above, resolving the
# workspace hostname to the endpoint's private IP.
resource "azurerm_private_endpoint" "this" {
  for_each = local.private_endpoints

  name                = each.value.name
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.pe_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = each.value.name
    private_connection_resource_id = var.workspace_resource_id
    subresource_names              = each.value.subresource_names
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "databricks-dns"
    private_dns_zone_ids = [azurerm_private_dns_zone.this.id]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.this]
}

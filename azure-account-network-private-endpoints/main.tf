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

# Private endpoints, SERIALIZED (v0.2.0): every endpoint creation triggers a workspace
# update (the private-endpoint connection writes onto the Databricks workspace resource),
# and the workspace rejects concurrent updates — parallel creation of two or more
# endpoints fails with ConcurrentUpdateError, leaving the loser created-in-Azure but
# absent-from-state (live 2026-10-27, the rc-bd1 journey). The depends_on chain
# back_end → front_end → browser_auth serializes the updates. A depends_on on a
# count=0 resource is a no-op, so every enabled combination is valid.
resource "azurerm_private_endpoint" "back_end" {
  name                = "${local.workspace_name}-be-pe"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.pe_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${local.workspace_name}-be-pe"
    private_connection_resource_id = var.workspace_resource_id
    subresource_names              = ["databricks_ui_api"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "databricks-dns"
    private_dns_zone_ids = [azurerm_private_dns_zone.this.id]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.this]
}

resource "azurerm_private_endpoint" "front_end" {
  count = var.enable_front_end_pe ? 1 : 0

  name                = "${local.workspace_name}-fe-pe"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.pe_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${local.workspace_name}-fe-pe"
    private_connection_resource_id = var.workspace_resource_id
    subresource_names              = ["databricks_ui_api"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "databricks-dns"
    private_dns_zone_ids = [azurerm_private_dns_zone.this.id]
  }

  depends_on = [azurerm_private_endpoint.back_end]
}

resource "azurerm_private_endpoint" "browser_auth" {
  count = var.enable_browser_auth_pe ? 1 : 0

  name                = "${local.workspace_name}-browser-auth-pe"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.pe_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${local.workspace_name}-browser-auth-pe"
    private_connection_resource_id = var.workspace_resource_id
    subresource_names              = ["browser_authentication"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "databricks-dns"
    private_dns_zone_ids = [azurerm_private_dns_zone.this.id]
  }

  depends_on = [azurerm_private_endpoint.front_end]
}

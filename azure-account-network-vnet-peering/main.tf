# Peering from local VNet to remote VNet (outbound direction).
resource "azurerm_virtual_network_peering" "local_to_remote" {
  name                         = "${var.local_vnet_name}-to-${var.remote_vnet_name}"
  resource_group_name          = var.local_resource_group_name
  virtual_network_name         = var.local_vnet_name
  remote_virtual_network_id    = var.remote_vnet_id
  allow_virtual_network_access = var.allow_virtual_network_access
  allow_forwarded_traffic      = var.allow_forwarded_traffic
  allow_gateway_transit        = var.allow_gateway_transit
  use_remote_gateways          = var.use_remote_gateways
}

# Peering from remote VNet back to local VNet (return direction).
# Both directions must exist for connectivity to be established.
resource "azurerm_virtual_network_peering" "remote_to_local" {
  name                         = "${var.remote_vnet_name}-to-${var.local_vnet_name}"
  resource_group_name          = var.remote_resource_group_name
  virtual_network_name         = var.remote_vnet_name
  remote_virtual_network_id    = var.local_vnet_id
  allow_virtual_network_access = var.allow_virtual_network_access
  allow_forwarded_traffic      = var.allow_forwarded_traffic
  # Gateway settings are reversed: the remote-to-local peering uses remote gateways
  # if the local side is transiting through the remote gateway.
  allow_gateway_transit = var.use_remote_gateways
  use_remote_gateways   = var.allow_gateway_transit
}

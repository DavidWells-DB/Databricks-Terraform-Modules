# Public IP for the Azure Firewall front-end. Azure Firewall requires at least one public IP
# when deployed in hub-and-spoke topologies. Standard SKU is mandatory for Azure Firewall.
resource "azurerm_public_ip" "this" {
  name                = local.public_ip_name
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags

  #checkov:skip=CKV_AZURE_47: DDoS protection plan association is a root-composition concern managed at the VNet level, not per-resource. Callers requiring DDoS protection attach a plan to the hub VNet.
}

# IP group containing all spoke subnet CIDR ranges. Used as the source address group in
# firewall network rules so that rules stay declarative and CIDR management is centralised.
resource "azurerm_ip_group" "this" {
  name                = local.ip_group_name
  resource_group_name = var.resource_group_name
  location            = var.location
  cidrs               = var.allowed_spoke_cidr_ranges

  tags = var.tags
}

# Firewall policy — carries the rule collection groups. Using a detached policy (rather than
# inline classic rules) allows rule updates without replacing the firewall resource itself.
resource "azurerm_firewall_policy" "this" {
  name                = local.firewall_policy_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.firewall_sku_tier

  tags = var.tags

  #checkov:skip=CKV_AZURE_220: DNS proxy is an operational decision; enabling it here couples the firewall to a specific DNS architecture. Callers that require DNS proxy should set dns.proxy_enabled = true via azurerm_firewall_policy after module creation.
}

# Rule collection group containing network rules for Databricks-specific Azure service tags.
# Network rules use Azure Service Tags to avoid managing explicit IP address lists, which
# change as Microsoft updates the service tag prefixes.
resource "azurerm_firewall_policy_rule_collection_group" "this" {
  name               = local.rule_collection_name
  firewall_policy_id = azurerm_firewall_policy.this.id
  priority           = 200

  network_rule_collection {
    name     = "databricks-service-tag-rules"
    priority = 300
    action   = "Allow"

    dynamic "rule" {
      for_each = var.service_tag_rules

      content {
        name                  = rule.value.name
        protocols             = rule.value.protocols
        source_ip_groups      = [azurerm_ip_group.this.id]
        destination_fqdns     = null
        destination_addresses = rule.value.destination_tags
        destination_ports     = rule.value.destination_ports
      }
    }
  }
}

# Azure Firewall deployed into the AzureFirewallSubnet. The firewall references the
# detached policy created above; this allows policy rule updates without firewall replacement.
resource "azurerm_firewall" "this" {
  name                = var.firewall_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_name            = "AZFW_VNet"
  sku_tier            = var.firewall_sku_tier
  firewall_policy_id  = azurerm_firewall_policy.this.id

  ip_configuration {
    name                 = "configuration"
    subnet_id            = var.firewall_subnet_id
    public_ip_address_id = azurerm_public_ip.this.id
  }

  tags = var.tags

  #checkov:skip=CKV_AZURE_216: Forced tunneling of management traffic is an advanced deployment concern. This module deploys the firewall in the standard hub-spoke topology; callers that require forced management tunneling should configure a separate management IP and subnet.
}

# Route table for spoke subnets — carries the single forced-tunnel route (0.0.0.0/0 →
# firewall private IP). The caller associates this route table with spoke subnets by
# referencing the route_table_id output.
#
# bgp_route_propagation_enabled = false: prevents VPN/ExpressRoute gateway routes from
# overriding the forced-tunnel default and bypassing the firewall.
resource "azurerm_route_table" "this" {
  name                          = local.route_table_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  bgp_route_propagation_enabled = false

  tags = var.tags
}

# Forced-tunnel route: 0.0.0.0/0 → Azure Firewall private IP (VirtualAppliance).
# This is the egress control route that forces all spoke traffic through the firewall
# for inspection before reaching the internet or Azure services.
resource "azurerm_route" "this" {
  name                   = local.forced_tunnel_route_name
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.this.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.this.ip_configuration[0].private_ip_address
}

# Associate the forced-tunnel route table with each spoke subnet via the caller-supplied
# subnet IDs. One association is created per entry in spoke_subnet_ids.
resource "azurerm_subnet_route_table_association" "spoke" {
  for_each = toset(var.spoke_subnet_ids)

  subnet_id      = each.value
  route_table_id = azurerm_route_table.this.id
}

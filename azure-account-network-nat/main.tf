# A NAT gateway + public IP for Azure Databricks VNet-injected subnets.
#
# WHY THIS MODULE (blueprint-gaps N2, High, 2026-11-05): the azure classic networking
# component builds the VNet only — no egress resource — and the workspace config defaults
# no_public_ip = true (Secure Cluster Connectivity). Without a NAT gateway (or another
# customer egress path) the cluster subnets have NO internet path: the AWS lanes got NAT
# via aws-account-network-egress-internet; Azure never got the equivalent. This module
# is it. On Azure NO route table is needed for this case: subnets without an explicit
# route table use the VNet system routes, and associating a NAT gateway with a subnet
# installs the 0.0.0.0/0 system route via the NAT gateway automatically.
#
# Subnet associations use the MAP pattern (for_each over name → subnet ID), NOT a list:
# the subnet IDs are typically outputs of the VNet module consumed in the SAME apply —
# known-after-apply values. for_each over a map keyed by caller-chosen names works
# (twice-proven: aws-account-network-vpc v0.3.0, azure-account-network-firewall v0.2.0);
# for_each over a list of computed IDs fails at apply ("Invalid for_each argument").

resource "azurerm_public_ip" "this" {
  # Standard SKU is required for NAT gateway association.
  name                = var.public_ip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_nat_gateway" "this" {
  name                = var.nat_gateway_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "Standard"
  tags                = var.tags
}

# azurerm 4.x renamed the argument public_ip_id -> public_ip_address_id.
resource "azurerm_nat_gateway_public_ip_association" "this" {
  nat_gateway_id       = azurerm_nat_gateway.this.id
  public_ip_address_id = azurerm_public_ip.this.id
}

# One association per subnet (name → subnet resource ID). Associating the NAT gateway
# with a subnet is what gives that subnet outbound internet access via the NAT.
resource "azurerm_subnet_nat_gateway_association" "this" {
  for_each = var.subnets

  subnet_id      = each.value
  nat_gateway_id = azurerm_nat_gateway.this.id
}

resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.vnet_cidr]
  tags                = var.tags
}

# Databricks VNet injection requires a single NSG associated to both the host and container subnets.
# The Databricks control plane injects its own NSG rules during workspace creation; the module
# creates the NSG empty and Databricks manages its rules post-creation.
# lifecycle.ignore_changes on security_rule: Databricks modifies NSG rules post-creation via the
# Azure Databricks resource provider — external mutation that Terraform should not fight.
resource "azurerm_network_security_group" "this" {
  name                = var.nsg_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  lifecycle {
    # Databricks injects NSG rules after workspace creation via the Azure resource provider.
    # Ignoring security_rule prevents Terraform from reverting control-plane-managed rules.
    ignore_changes = [security_rule]
  }
}

# Host subnet: carries the Databricks worker VMs (compute nodes).
# Service delegation to Microsoft.Databricks/workspaces is required for VNet injection.
resource "azurerm_subnet" "host" {
  name                 = var.host_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.host_subnet_cidr]

  delegation {
    name = "databricks-host-delegation"

    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  }
}

# Container subnet: carries the Databricks container (serverless driver) plane traffic.
# Service delegation to Microsoft.Databricks/workspaces is required for VNet injection.
resource "azurerm_subnet" "container" {
  name                 = var.container_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.container_subnet_cidr]

  delegation {
    name = "databricks-container-delegation"

    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  }
}

# Optional subnet for Azure Private Endpoints (e.g., Databricks back-end PE, storage PEs).
# Private endpoints must NOT have service delegation; network policies must be disabled
# (enforced by the PE resource itself, or configured via private_endpoint_network_policies).
resource "azurerm_subnet" "pe" {
  count = local.create_pe_subnet ? 1 : 0

  name                 = var.pe_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.pe_subnet_cidr]

  # Private endpoint network policies must be disabled for PE subnet.
  # "Disabled" is the required value for private endpoint subnets.
  private_endpoint_network_policies = "Disabled"
}

# Associate the shared NSG with the host subnet.
resource "azurerm_subnet_network_security_group_association" "host" {
  subnet_id                 = azurerm_subnet.host.id
  network_security_group_id = azurerm_network_security_group.this.id
}

# Associate the shared NSG with the container subnet.
resource "azurerm_subnet_network_security_group_association" "container" {
  subnet_id                 = azurerm_subnet.container.id
  network_security_group_id = azurerm_network_security_group.this.id
}

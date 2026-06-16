terraform {
  required_version = ">= 1.7.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.75"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
}

module "network_firewall" {
  source = "../.."

  resource_group_name = var.resource_group_name
  location            = var.location
  firewall_name       = "hub-databricks-firewall"
  firewall_subnet_id  = var.firewall_subnet_id
  spoke_subnet_ids    = var.spoke_subnet_ids

  allowed_spoke_cidr_ranges = var.allowed_spoke_cidr_ranges

  # Databricks-required Azure service tag rules for eastus.
  # Adjust service tags to match the target Azure region.
  # See: https://learn.microsoft.com/en-us/azure/databricks/security/network/classic/udr
  service_tag_rules = [
    {
      name              = "allow-databricks-control-plane"
      priority          = 100
      action            = "Allow"
      destination_tags  = ["AzureDatabricks"]
      destination_ports = ["443"]
      protocols         = ["TCP"]
    },
    {
      name              = "allow-storage-eastus"
      priority          = 110
      action            = "Allow"
      destination_tags  = ["Storage.EastUS"]
      destination_ports = ["443"]
      protocols         = ["TCP"]
    },
    {
      name              = "allow-eventhub-eastus"
      priority          = 120
      action            = "Allow"
      destination_tags  = ["EventHub.EastUS"]
      destination_ports = ["9093"]
      protocols         = ["TCP"]
    },
  ]

  firewall_sku_tier = "Premium"

  tags = {
    Module  = "azure-account-network-firewall"
    Example = "basic"
  }
}

variable "azure_subscription_id" {
  type        = string
  description = "Azure subscription ID for the provider."
}

variable "resource_group_name" {
  type        = string
  description = "Azure resource group where the hub firewall resources will be created."
}

variable "location" {
  type        = string
  description = "Azure region for all resources."
  default     = "eastus"
}

variable "firewall_subnet_id" {
  type        = string
  description = "Resource ID of the AzureFirewallSubnet (must be named exactly \"AzureFirewallSubnet\", minimum /26). Typically from the hub VNet created by azure-account-network-vnet."
}

variable "spoke_subnet_ids" {
  type        = list(string)
  description = "List of spoke subnet resource IDs to force-tunnel through the firewall (e.g., Databricks host and container subnets)."
}

variable "allowed_spoke_cidr_ranges" {
  type        = list(string)
  description = "List of spoke VNet CIDR ranges to include in the firewall IP group and source rules."
}

output "firewall_id" {
  value = module.network_firewall.firewall_id
}

output "firewall_private_ip" {
  value = module.network_firewall.firewall_private_ip
}

output "firewall_public_ip" {
  value = module.network_firewall.firewall_public_ip
}

output "firewall_policy_id" {
  value = module.network_firewall.firewall_policy_id
}

output "route_table_id" {
  value = module.network_firewall.route_table_id
}

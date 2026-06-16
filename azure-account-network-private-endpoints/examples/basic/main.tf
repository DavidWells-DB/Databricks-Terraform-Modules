terraform {
  required_version = ">= 1.7.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.63"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

module "private_endpoints" {
  source = "../.."

  resource_group_name   = var.resource_group_name
  location              = var.location
  workspace_resource_id = var.workspace_resource_id
  pe_subnet_id          = var.pe_subnet_id
  vnet_id               = var.vnet_id

  # Optional: enable front-end PE for clients outside the injected VNet.
  enable_front_end_pe = false

  # Optional: enable browser auth PE for SSO callback when public access is disabled.
  enable_browser_auth_pe = false

  # Optional: hub VNet IDs for cross-VNet DNS resolution.
  hub_vnet_ids = []

  tags = {
    Module  = "azure-account-network-private-endpoints"
    Example = "basic"
  }
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID for the provider."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group in which to create private endpoint resources."
}

variable "location" {
  type        = string
  description = "Azure region (e.g., \"eastus\"). Must match the Databricks workspace region."
}

variable "workspace_resource_id" {
  type        = string
  description = "Azure resource ID of the Databricks workspace."
}

variable "pe_subnet_id" {
  type        = string
  description = "Azure resource ID of the subnet for private endpoint NICs. Private endpoint network policies must be disabled."
}

variable "vnet_id" {
  type        = string
  description = "Azure resource ID of the spoke VNet to link to the private DNS zone."
}

output "back_end_pe_id" {
  description = "Azure resource ID of the back-end private endpoint."
  value       = module.private_endpoints.back_end_pe_id
}

output "private_dns_zone_id" {
  description = "Azure resource ID of the private DNS zone."
  value       = module.private_endpoints.private_dns_zone_id
}

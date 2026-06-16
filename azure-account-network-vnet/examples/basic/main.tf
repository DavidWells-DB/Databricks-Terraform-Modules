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
  subscription_id = var.subscription_id
}

module "vnet" {
  source = "../.."

  resource_group_name   = var.resource_group_name
  location              = var.location
  vnet_name             = "databricks-vnet"
  vnet_cidr             = "10.0.0.0/16"
  host_subnet_name      = "databricks-host"
  host_subnet_cidr      = "10.0.1.0/24"
  container_subnet_name = "databricks-container"
  container_subnet_cidr = "10.0.2.0/24"
  nsg_name              = "databricks-nsg"

  # Optional: uncomment to create a private endpoint subnet
  # pe_subnet_name = "databricks-pe"
  # pe_subnet_cidr = "10.0.3.0/27"

  tags = {
    Module  = "azure-account-network-vnet"
    Example = "basic"
  }
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID for the provider."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the Azure resource group in which to create the VNet."
}

variable "location" {
  type        = string
  description = "Azure region (e.g. \"eastus\", \"westeurope\")."
  default     = "eastus"
}

output "vnet_id" {
  value = module.vnet.vnet_id
}

output "host_subnet_id" {
  value = module.vnet.host_subnet_id
}

output "container_subnet_id" {
  value = module.vnet.container_subnet_id
}

output "nsg_id" {
  value = module.vnet.nsg_id
}

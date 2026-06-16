terraform {
  required_version = ">= 1.7.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

module "vnet_peering" {
  source = "../.."

  local_vnet_name            = var.local_vnet_name
  remote_vnet_name           = var.remote_vnet_name
  local_vnet_id              = var.local_vnet_id
  remote_vnet_id             = var.remote_vnet_id
  local_resource_group_name  = var.local_resource_group_name
  remote_resource_group_name = var.remote_resource_group_name
  allow_forwarded_traffic    = true
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID."
}

variable "local_vnet_name" {
  type        = string
  description = "Name of the local (spoke/Databricks-injected) virtual network."
}

variable "remote_vnet_name" {
  type        = string
  description = "Name of the remote (hub) virtual network."
}

variable "local_vnet_id" {
  type        = string
  description = "Full Azure resource ID of the local virtual network."
}

variable "remote_vnet_id" {
  type        = string
  description = "Full Azure resource ID of the remote virtual network."
}

variable "local_resource_group_name" {
  type        = string
  description = "Resource group containing the local virtual network."
}

variable "remote_resource_group_name" {
  type        = string
  description = "Resource group containing the remote virtual network."
}

output "local_peering_id" {
  description = "Azure resource ID of the local-to-remote VNet peering."
  value       = module.vnet_peering.local_peering_id
}

output "remote_peering_id" {
  description = "Azure resource ID of the remote-to-local VNet peering."
  value       = module.vnet_peering.remote_peering_id
}

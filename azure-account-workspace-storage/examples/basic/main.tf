terraform {
  required_version = ">= 1.7.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.50"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
}

module "workspace_storage" {
  source = "../.."

  resource_group_name = var.resource_group_name
  location            = var.location
  resource_prefix     = var.resource_prefix

  account_replication_type = "LRS"

  tags = {
    Module  = "azure-account-workspace-storage"
    Example = "basic"
  }
}

variable "azure_subscription_id" {
  type        = string
  description = "Azure subscription ID for the provider."
}

variable "resource_group_name" {
  type        = string
  description = "Azure resource group where storage resources will be created."
}

variable "location" {
  type        = string
  description = "Azure region for all resources."
  default     = "eastus"
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for naming storage resources. Must be 1-16 chars, lowercase alphanumeric. Should include a unique component (e.g. workspace name + random suffix)."
}

output "storage_account_name" {
  value = module.workspace_storage.storage_account_name
}

output "storage_account_id" {
  value = module.workspace_storage.storage_account_id
}

output "container_name" {
  value = module.workspace_storage.container_name
}

output "dfs_endpoint" {
  value = module.workspace_storage.dfs_endpoint
}

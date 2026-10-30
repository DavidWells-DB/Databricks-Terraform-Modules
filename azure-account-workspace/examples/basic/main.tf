terraform {
  required_version = ">= 1.7.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.76"
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">= 1.9"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "azapi" {}

module "workspace" {
  source = "../.."

  name              = var.workspace_name
  resource_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg"
  location          = var.location
  sku               = "premium"

  tags = {
    Module  = "azure-account-workspace"
    Example = "basic"
  }
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID for the provider."
}

variable "location" {
  type        = string
  description = "Azure region for the workspace and resource group (e.g., \"eastus\")."
  default     = "eastus"
}

variable "workspace_name" {
  type        = string
  description = "Name for the Azure Databricks workspace."
}

output "workspace_id" {
  value = module.workspace.workspace_id
}

output "workspace_url" {
  value = module.workspace.workspace_url
}

output "workspace_resource_id" {
  value = module.workspace.workspace_resource_id
}

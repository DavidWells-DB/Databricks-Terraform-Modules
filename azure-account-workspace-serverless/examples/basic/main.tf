terraform {
  required_version = ">= 1.7.0"
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
  }
}

provider "azapi" {
  subscription_id = var.azure_subscription_id
}

module "workspace_serverless" {
  source = "../.."

  name              = var.workspace_name
  resource_group_id = "/subscriptions/${var.azure_subscription_id}/resourceGroups/${var.resource_group_name}"
  location          = var.location

  tags = {
    Module  = "azure-account-workspace-serverless"
    Example = "basic"
  }
}

variable "azure_subscription_id" {
  type        = string
  description = "Azure subscription ID for the provider."
}

variable "resource_group_name" {
  type        = string
  description = "Azure resource group (pre-existing) where the Databricks workspace will be created. Must be in a region that supports serverless workspaces."
}

variable "location" {
  type        = string
  description = "Azure region for the workspace (e.g. \"eastus2\"). Must support serverless workspaces."
  default     = "eastus2"
}

variable "workspace_name" {
  type        = string
  description = "Name for the Databricks workspace resource. Must be 3-64 chars, alphanumeric and hyphens, start/end with alphanumeric."
  default     = "adb-serverless-example"
}

output "workspace_id" {
  value = module.workspace_serverless.workspace_id
}

output "workspace_url" {
  value = module.workspace_serverless.workspace_url
}

output "workspace_resource_id" {
  value = module.workspace_serverless.workspace_resource_id
}

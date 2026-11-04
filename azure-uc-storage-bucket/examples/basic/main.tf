terraform {
  required_version = ">= 1.7.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.70"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

module "uc_storage" {
  source = "../.."

  resource_group_name = var.resource_group_name
  location            = var.location

  storage_account_name = var.storage_account_name
  container_name       = var.container_name

  tags = {
    module  = "azure-uc-storage-bucket"
    example = "basic"
  }
}

variable "resource_group_name" {
  type        = string
  description = "Name of the Azure resource group for the storage account."
}

variable "location" {
  type        = string
  description = "Azure region for the storage account (e.g. \"eastus\")."
}

variable "storage_account_name" {
  type        = string
  description = "Globally unique name of the dedicated ADLS Gen2 storage account (3-24 chars, lowercase alphanumeric). A common convention: \"<catalog-name-without-underscores>ucst\"."
}

variable "container_name" {
  type        = string
  description = "Name of the dedicated container for the catalog's managed data."
  default     = "catalog"
}

output "storage_root" {
  description = "Unity Catalog storage-root URL (abfss://<container>@<account>.dfs.core.windows.net)."
  value       = module.uc_storage.storage_root
}

output "storage_account_id" {
  description = "ARM resource ID of the dedicated storage account. Feed to azure-uc-storage-credential's storage_account_id."
  value       = module.uc_storage.storage_account_id
}

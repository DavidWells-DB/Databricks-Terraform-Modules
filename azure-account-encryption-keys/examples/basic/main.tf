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
  tenant_id       = var.tenant_id
}

module "encryption_keys" {
  source = "../.."

  resource_group_name                    = var.resource_group_name
  location                               = var.location
  key_vault_name                         = var.key_vault_name
  tenant_id                              = var.tenant_id
  databricks_service_principal_object_id = var.databricks_service_principal_object_id
  azure_client_object_id                 = var.azure_client_object_id
  soft_delete_retention_days             = 7

  tags = {
    Module  = "azure-account-encryption-keys"
    Example = "basic"
  }
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID."
}

variable "tenant_id" {
  type        = string
  description = "Azure Active Directory tenant ID."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the Azure resource group where the Key Vault will be created."
}

variable "location" {
  type        = string
  description = "Azure region for the Key Vault."
  default     = "eastus"
}

variable "key_vault_name" {
  type        = string
  description = "Globally unique name for the Azure Key Vault (3-24 chars, alphanumeric and hyphens)."
}

variable "databricks_service_principal_object_id" {
  type        = string
  description = "Object ID of the AzureDatabricks enterprise application in your Azure AD tenant. Find via: az ad sp show --id 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --query id -o tsv"
}

variable "azure_client_object_id" {
  type        = string
  description = "Object ID of the Azure service principal or user running Terraform."
}

output "key_vault_id" {
  value = module.encryption_keys.key_vault_id
}

output "managed_services_key_id" {
  value = module.encryption_keys.managed_services_key_id
}

output "workspace_storage_key_id" {
  value = module.encryption_keys.workspace_storage_key_id
}

output "managed_disk_key_id" {
  value = module.encryption_keys.managed_disk_key_id
}

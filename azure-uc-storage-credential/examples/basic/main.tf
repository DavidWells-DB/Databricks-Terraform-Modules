terraform {
  required_version = ">= 1.7.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.75"
    }
    databricks = {
      source  = "databricks/databricks"
      version = ">= 1.49"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
}

provider "databricks" {
  alias         = "workspace"
  host          = var.databricks_workspace_url
  client_id     = var.databricks_client_id
  client_secret = var.databricks_client_secret
}

module "uc_storage_credential" {
  source = "../.."

  providers = {
    databricks.workspace = databricks.workspace
  }

  resource_group_name = var.resource_group_name
  location            = var.location
  storage_account_id  = var.storage_account_id
  credential_name     = "example-uc-cred"

  comment = "Unity Catalog storage credential for the example ADLS Gen2 account"

  tags = {
    Module  = "azure-uc-storage-credential"
    Example = "basic"
  }
}

variable "azure_subscription_id" {
  type        = string
  description = "Azure subscription ID for the provider."
}

variable "resource_group_name" {
  type        = string
  description = "Azure resource group name for the Access Connector."
}

variable "location" {
  type        = string
  description = "Azure region (e.g. \"eastus\")."
  default     = "eastus"
}

variable "storage_account_id" {
  type        = string
  description = "Full Azure resource ID of the ADLS Gen2 storage account."
}

variable "databricks_workspace_url" {
  type        = string
  description = "Databricks workspace URL (e.g. https://adb-1234567890.1.azuredatabricks.net)."
}

variable "databricks_client_id" {
  type        = string
  description = "Databricks workspace-level service principal application ID (OAuth M2M)."
}

variable "databricks_client_secret" {
  type        = string
  description = "Databricks workspace-level service principal secret (OAuth M2M)."
  sensitive   = true
}

output "access_connector_id" {
  value = module.uc_storage_credential.access_connector_id
}

output "access_connector_principal_id" {
  value = module.uc_storage_credential.access_connector_principal_id
}

output "storage_credential_id" {
  value = module.uc_storage_credential.storage_credential_id
}

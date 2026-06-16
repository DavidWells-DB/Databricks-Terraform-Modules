terraform {
  required_version = ">= 1.7.0"
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = ">= 1.50"
    }
  }
}

provider "databricks" {
  alias         = "account"
  host          = var.databricks_account_host
  account_id    = var.databricks_account_id
  client_id     = var.databricks_client_id
  client_secret = var.databricks_client_secret
}

module "ncc" {
  source = "../.."

  providers = {
    databricks.account = databricks.account
  }

  databricks_account_id = var.databricks_account_id
  name                  = "ncc-eastus-example"
  region                = "eastus"
}

variable "databricks_account_host" {
  type        = string
  description = "Databricks Azure account host. Commercial: https://accounts.azuredatabricks.net."
  default     = "https://accounts.azuredatabricks.net"
}

variable "databricks_account_id" {
  type        = string
  description = "Databricks account ID."
}

variable "databricks_client_id" {
  type        = string
  description = "Databricks account-level service principal application ID (OAuth M2M)."
}

variable "databricks_client_secret" {
  type        = string
  description = "Databricks account-level service principal secret (OAuth M2M)."
  sensitive   = true
}

output "network_connectivity_config_id" {
  description = "NCC ID to pass to databricks_mws_ncc_binding or workspace creation."
  value       = module.ncc.network_connectivity_config_id
}

output "ncc_name" {
  description = "Name of the created NCC."
  value       = module.ncc.ncc_name
}

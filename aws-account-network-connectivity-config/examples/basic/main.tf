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

  region = var.region
  name   = "ncc-${var.region}"
}

variable "region" {
  type        = string
  description = "AWS region for the Network Connectivity Configuration."
  default     = "us-east-1"
}

variable "databricks_account_host" {
  type        = string
  description = "Databricks account host. Commercial: https://accounts.cloud.databricks.com. GovCloud civilian: https://accounts.cloud.databricks.us. DoD: https://accounts-dod.cloud.databricks.mil."
  default     = "https://accounts.cloud.databricks.com"
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
  description = "NCC ID to pass to workspace binding (databricks_mws_ncc_binding)."
  value       = module.ncc.network_connectivity_config_id
}

output "name" {
  description = "Name of the created Network Connectivity Configuration."
  value       = module.ncc.name
}

terraform {
  required_version = ">= 1.7.0"
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = ">= 1.81.0"
    }
  }
}

provider "databricks" {
  alias      = "account"
  host       = var.databricks_account_host
  account_id = var.databricks_account_id

  client_id     = var.databricks_client_id
  client_secret = var.databricks_client_secret
}

module "network_policy_binding" {
  source = "../.."

  providers = {
    databricks.account = databricks.account
  }

  workspace_id      = var.workspace_id
  network_policy_id = var.network_policy_id
}

variable "databricks_account_host" {
  type        = string
  description = "Databricks account-level host. Commercial: https://accounts.cloud.databricks.com."
  default     = "https://accounts.cloud.databricks.com"
}

variable "databricks_account_id" {
  type        = string
  description = "Databricks account ID."
}

variable "databricks_client_id" {
  type        = string
  description = "Databricks service principal application ID (OAuth M2M) with account-admin."
}

variable "databricks_client_secret" {
  type        = string
  description = "Databricks service principal client secret (OAuth M2M)."
  sensitive   = true
}

variable "workspace_id" {
  type        = number
  description = "Databricks workspace ID to bind the network policy to."
}

variable "network_policy_id" {
  type        = string
  description = "Account network policy ID to bind (from dbx-account-network-policy)."
}

output "binding_id" {
  value = module.network_policy_binding.binding_id
}

output "network_policy_id" {
  value = module.network_policy_binding.network_policy_id
}

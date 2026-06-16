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

provider "databricks" {
  alias      = "workspace"
  host       = var.databricks_workspace_url
  account_id = var.databricks_account_id

  client_id     = var.databricks_client_id
  client_secret = var.databricks_client_secret
}

module "workspace_network_serverless" {
  source = "../.."

  providers = {
    databricks.account   = databricks.account
    databricks.workspace = databricks.workspace
  }

  workspace_id                   = var.workspace_id
  network_connectivity_config_id = var.network_connectivity_config_id

  # No private endpoint rules or network policy in the basic example.
  # Add private_endpoint_rules and network_policy_id for a fuller configuration.
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

variable "databricks_workspace_url" {
  type        = string
  description = "Databricks workspace URL (e.g. https://<workspace-id>.cloud.databricks.com)."
}

variable "databricks_client_id" {
  type        = string
  description = "Databricks service principal application ID (OAuth M2M). Must have account-admin for account-level resources and workspace-admin for workspace-level resources."
}

variable "databricks_client_secret" {
  type        = string
  description = "Databricks service principal client secret (OAuth M2M)."
  sensitive   = true
}

variable "workspace_id" {
  type        = number
  description = "Databricks workspace ID to bind the NCC to."
}

variable "network_connectivity_config_id" {
  type        = string
  description = "NCC ID to bind. The NCC must exist in the same Databricks account and region as the workspace."
}

output "ncc_binding_id" {
  description = "Composite NCC binding identifier."
  value       = module.workspace_network_serverless.ncc_binding_id
}

output "network_connectivity_config_id" {
  description = "NCC ID bound to the workspace."
  value       = module.workspace_network_serverless.network_connectivity_config_id
}

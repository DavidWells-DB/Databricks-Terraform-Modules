terraform {
  required_version = ">= 1.7.0"
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = ">= 1.50"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9"
    }
  }
}

provider "databricks" {
  alias      = "account"
  host       = "https://accounts.gcp.databricks.com"
  account_id = var.databricks_account_id
  # Authenticate via DATABRICKS_CLIENT_ID and DATABRICKS_CLIENT_SECRET env vars,
  # or google_service_account impersonation when running under a GCP service account.
}

module "workspace" {
  source = "../.."

  providers = {
    databricks.account = databricks.account
  }

  databricks_account_id    = var.databricks_account_id
  workspace_name           = var.workspace_name
  project_id               = var.project_id
  region                   = var.region
  resource_prefix          = var.resource_prefix
  storage_configuration_id = var.storage_configuration_id
  databricks_network_id    = var.databricks_network_id

  custom_tags = {
    module  = "gcp-account-workspace"
    example = "basic"
  }
}

variable "databricks_account_id" {
  type        = string
  description = "Databricks account ID."
}

variable "workspace_name" {
  type        = string
  description = "Name for the Databricks workspace."
}

variable "project_id" {
  type        = string
  description = "GCP project ID."
}

variable "region" {
  type        = string
  description = "GCP region for the workspace data plane."
  default     = "us-central1"
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for derived workspace resource names."
}

variable "storage_configuration_id" {
  type        = string
  description = "Databricks storage configuration ID from gcp-account-workspace-storage."
}

variable "databricks_network_id" {
  type        = string
  description = "Databricks network configuration ID from gcp-account-network-vpc."
}

output "workspace_id" {
  value = module.workspace.workspace_id
}

output "workspace_url" {
  value = module.workspace.workspace_url
}

output "dns_propagation_complete" {
  value = module.workspace.dns_propagation_complete
}

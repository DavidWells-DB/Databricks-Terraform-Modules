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
  alias         = "account"
  host          = var.databricks_account_host
  account_id    = var.databricks_account_id
  client_id     = var.databricks_client_id
  client_secret = var.databricks_client_secret
}

module "serverless_workspace" {
  source = "../.."

  providers = {
    databricks.account = databricks.account
  }

  databricks_account_id = var.databricks_account_id
  workspace_name        = "example-serverless"
  project_id            = var.project_id
  region                = var.region
  resource_prefix       = "example"

  custom_tags = {
    Module  = "gcp-account-workspace-serverless"
    Example = "basic"
  }
}

variable "databricks_account_host" {
  type        = string
  description = "Databricks account host for GCP. Use https://accounts.gcp.databricks.com."
  default     = "https://accounts.gcp.databricks.com"
}

variable "databricks_account_id" {
  type        = string
  description = "Databricks account ID (UUID)."
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

variable "project_id" {
  type        = string
  description = "GCP project ID in which the serverless workspace is created."
}

variable "region" {
  type        = string
  description = "GCP region for the workspace (e.g. \"us-central1\")."
  default     = "us-central1"
}

output "workspace_id" {
  value = module.serverless_workspace.workspace_id
}

output "workspace_url" {
  value = module.serverless_workspace.workspace_url
}

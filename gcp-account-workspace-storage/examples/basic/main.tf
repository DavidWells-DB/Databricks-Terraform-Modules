terraform {
  required_version = ">= 1.7.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = ">= 1.50"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "databricks" {
  alias      = "account"
  host       = "https://accounts.gcp.databricks.com"
  account_id = var.databricks_account_id
  # Authenticate via DATABRICKS_CLIENT_ID and DATABRICKS_CLIENT_SECRET env vars,
  # or google_service_account impersonation when running under a GCP service account.
}

module "workspace_storage" {
  source = "../.."

  providers = {
    databricks.account = databricks.account
  }

  databricks_account_id            = var.databricks_account_id
  project_id                       = var.project_id
  region                           = var.region
  resource_prefix                  = var.resource_prefix
  databricks_service_account_email = var.databricks_service_account_email

  labels = {
    module  = "gcp-account-workspace-storage"
    example = "basic"
  }
}

variable "project_id" {
  type        = string
  description = "GCP project ID."
}

variable "region" {
  type        = string
  description = "GCP region for the GCS bucket."
  default     = "us-central1"
}

variable "databricks_account_id" {
  type        = string
  description = "Databricks account ID."
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for the GCS bucket and Databricks storage configuration name."
}

variable "databricks_service_account_email" {
  type        = string
  description = "Databricks-managed GCP service account email granted IAM access to the bucket."
}

output "storage_configuration_id" {
  value = module.workspace_storage.storage_configuration_id
}

output "bucket_name" {
  value = module.workspace_storage.bucket_name
}

output "bucket_url" {
  value = module.workspace_storage.bucket_url
}

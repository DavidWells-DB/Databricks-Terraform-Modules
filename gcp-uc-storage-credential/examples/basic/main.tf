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
  project = var.gcp_project_id
}

provider "databricks" {
  alias         = "workspace"
  host          = var.databricks_workspace_url
  client_id     = var.databricks_client_id
  client_secret = var.databricks_client_secret
}

module "storage_credential" {
  source = "../.."

  providers = {
    databricks.workspace = databricks.workspace
  }

  credential_name = "example-gcs-credential"
  bucket_name     = var.bucket_name
  comment         = "Managed by Terraform — gcp-uc-storage-credential example/basic"
}

variable "gcp_project_id" {
  type        = string
  description = "GCP project ID for the Google provider."
}

variable "bucket_name" {
  type        = string
  description = "Name of the existing GCS bucket to grant the Databricks service account access to."
}

variable "databricks_workspace_url" {
  type        = string
  description = "Databricks workspace URL (e.g. https://adb-1234567890.12.azuredatabricks.net or the GCP equivalent)."
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

output "storage_credential_id" {
  description = "Databricks UC storage credential ID."
  value       = module.storage_credential.storage_credential_id
}

output "databricks_service_account_email" {
  description = "Email of the Databricks-managed GCP service account."
  value       = module.storage_credential.databricks_service_account_email
}

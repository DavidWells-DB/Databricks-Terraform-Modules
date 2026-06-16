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
}

provider "databricks" {
  alias      = "account"
  host       = "https://accounts.gcp.databricks.com"
  account_id = var.databricks_account_id
  # Authenticate via DATABRICKS_CLIENT_ID and DATABRICKS_CLIENT_SECRET env vars,
  # or via google_service_account impersonation for GCP-native auth.
}

module "provisioning_service_account" {
  source = "../.."

  providers = {
    databricks.account = databricks.account
  }

  project_id      = var.project_id
  resource_prefix = "example"
  delegate_emails = var.delegate_emails
}

variable "project_id" {
  type        = string
  description = "GCP project ID."
}

variable "databricks_account_id" {
  type        = string
  description = "Databricks account ID (UUID)."
}

variable "delegate_emails" {
  type        = list(string)
  description = "Emails that may impersonate the provisioner service account. Optional."
  default     = []
}

output "service_account_email" {
  description = "Email of the created GCP service account."
  value       = module.provisioning_service_account.service_account_email
}

output "custom_role_id" {
  description = "Fully-qualified custom IAM role name."
  value       = module.provisioning_service_account.custom_role_id
}

output "databricks_user_id" {
  description = "Databricks account-level user ID of the service account."
  value       = module.provisioning_service_account.databricks_user_id
}

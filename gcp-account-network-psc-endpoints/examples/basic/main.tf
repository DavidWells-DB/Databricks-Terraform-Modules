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
  alias         = "account"
  host          = "https://accounts.gcp.databricks.com"
  account_id    = var.databricks_account_id
  client_id     = var.databricks_client_id
  client_secret = var.databricks_client_secret
}

module "psc_endpoints" {
  source = "../.."

  providers = {
    databricks.account = databricks.account
  }

  databricks_account_id = var.databricks_account_id
  project_id            = var.project_id
  region                = var.region
  network_self_link     = var.network_self_link
  psc_subnet_self_link  = var.psc_subnet_self_link
  resource_prefix       = var.resource_prefix

  public_access_enabled = true
  private_access_level  = "ACCOUNT"
}

variable "project_id" {
  type        = string
  description = "GCP project ID."
}

variable "region" {
  type        = string
  description = "GCP region for PSC endpoints."
  default     = "us-central1"
}

variable "network_self_link" {
  type        = string
  description = "Self-link of the GCP VPC network."
}

variable "psc_subnet_self_link" {
  type        = string
  description = "Self-link of the subnet for PSC IP address allocation."
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all resource names."
  default     = "dbx-psc"
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

output "workspace_psc_endpoint_id" {
  value = module.psc_endpoints.workspace_psc_endpoint_id
}

output "relay_psc_endpoint_id" {
  value = module.psc_endpoints.relay_psc_endpoint_id
}

output "private_access_settings_id" {
  value = module.psc_endpoints.private_access_settings_id
}

output "workspace_psc_ip" {
  value = module.psc_endpoints.workspace_psc_ip
}

output "relay_psc_ip" {
  value = module.psc_endpoints.relay_psc_ip
}

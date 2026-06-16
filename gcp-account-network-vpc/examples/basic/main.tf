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
  # Authenticate via GOOGLE_CREDENTIALS env var or Application Default Credentials.
}

module "network" {
  source = "../.."

  providers = {
    databricks.account = databricks.account
  }

  project_id                   = var.project_id
  region                       = var.region
  resource_prefix              = var.resource_prefix
  databricks_account_id        = var.databricks_account_id
  network_name                 = var.network_name
  network_cidr                 = "10.0.0.0/16"
  pod_secondary_range_cidr     = "10.1.0.0/16"
  service_secondary_range_cidr = "10.2.0.0/20"
}

variable "project_id" {
  type        = string
  description = "GCP project ID for the VPC and network resources."
}

variable "region" {
  type        = string
  description = "GCP region for the subnetwork (e.g. \"us-central1\")."
  default     = "us-central1"
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for all created GCP resource names."
  default     = "dbx-basic"
}

variable "databricks_account_id" {
  type        = string
  description = "Databricks account ID (UUID)."
}

variable "network_name" {
  type        = string
  description = "Name for the Databricks network registration."
  default     = "basic-network"
}

output "databricks_network_id" {
  description = "Databricks network configuration ID. Pass to workspace creation modules as their network_id input."
  value       = module.network.databricks_network_id
}

output "network_self_link" {
  description = "Self-link of the created VPC."
  value       = module.network.network_self_link
}

output "subnetwork_self_link" {
  description = "Self-link of the created subnetwork."
  value       = module.network.subnetwork_self_link
}

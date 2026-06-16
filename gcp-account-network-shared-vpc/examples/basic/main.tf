terraform {
  required_version = ">= 1.7.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

provider "google" {
  project = var.host_project_id
  region  = var.region
}

module "shared_vpc" {
  source = "../.."

  host_project_id     = var.host_project_id
  service_project_ids = var.service_project_ids

  subnet_iam_grants = [
    {
      subnetwork = var.databricks_subnet_name
      region     = var.region
      member     = "serviceAccount:${var.databricks_service_account_email}"
      role       = "roles/compute.networkUser"
    },
  ]
}

variable "host_project_id" {
  type        = string
  description = "GCP project ID of the Shared VPC host project."
}

variable "service_project_ids" {
  type        = list(string)
  description = "GCP project IDs to attach as Shared VPC service projects."
}

variable "region" {
  type        = string
  description = "GCP region for the provider and subnet IAM grant."
  default     = "us-central1"
}

variable "databricks_subnet_name" {
  type        = string
  description = "Name of the subnetwork in the host project to grant Databricks service accounts access to."
}

variable "databricks_service_account_email" {
  type        = string
  description = "Email of the GCP service account (from the Databricks service project) that needs compute.networkUser on the Shared VPC subnet."
}

output "host_project_id" {
  description = "GCP project ID of the Shared VPC host project."
  value       = module.shared_vpc.host_project_id
}

output "service_project_attachment_ids" {
  description = "Map of service project ID to Shared VPC attachment resource ID."
  value       = module.shared_vpc.service_project_attachment_ids
}

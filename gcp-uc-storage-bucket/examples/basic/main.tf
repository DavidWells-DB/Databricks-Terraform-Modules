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
  project = var.project_id
  region  = var.region
}

module "uc_storage_bucket" {
  source = "../.."

  bucket_name   = var.bucket_name
  location      = var.location
  force_destroy = var.force_destroy

  labels = {
    module  = "gcp-uc-storage-bucket"
    example = "basic"
  }
}

variable "project_id" {
  type        = string
  description = "GCP project ID for the bucket."
}

variable "region" {
  type        = string
  description = "GCP region for the google provider."
  default     = "us-central1"
}

variable "bucket_name" {
  type        = string
  description = "Globally unique name of the dedicated GCS bucket for a Unity Catalog catalog's managed storage. A common convention: \"<catalog-name>-uc\" with an org suffix."
}

variable "location" {
  type        = string
  description = "GCS bucket location (region, multi-region e.g. \"US\", or dual-region)."
  default     = "US"
}

variable "force_destroy" {
  type        = bool
  description = "Allow the bucket and all contained objects to be destroyed by Terraform."
  default     = false
}

output "storage_root" {
  description = "Unity Catalog storage-root URL for the bucket (gs://<bucket>)."
  value       = module.uc_storage_bucket.storage_root
}

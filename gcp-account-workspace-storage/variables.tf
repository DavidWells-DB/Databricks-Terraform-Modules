variable "databricks_account_id" {
  type        = string
  description = "Databricks account ID. Used in the databricks_mws_storage_configurations registration."
  nullable    = false
}

variable "project_id" {
  type        = string
  description = "GCP project ID in which the GCS bucket will be created."
  nullable    = false
}

variable "region" {
  type        = string
  description = "GCP region for the GCS bucket (e.g. \"us-central1\"). Must match the region of the Databricks workspace."
  nullable    = false
}

variable "resource_prefix" {
  type        = string
  description = "Prefix applied to the GCS bucket name and the Databricks storage configuration name. Must be 1-38 characters; lowercase letters, digits, and hyphens only. GCS bucket names have a 63-character limit; the module appends \"-root-storage\" (13 chars), leaving 50 for the prefix."
  nullable    = false
  validation {
    condition     = length(var.resource_prefix) >= 1 && length(var.resource_prefix) <= 38 && can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$|^[a-z0-9]$", var.resource_prefix))
    error_message = "resource_prefix must be 1-38 characters, contain only lowercase letters, digits, and hyphens, and must start and end with a letter or digit."
  }
}

variable "databricks_service_account_email" {
  type        = string
  description = "Email address of the Databricks-managed GCP service account that will be granted IAM access to the bucket. Provided by Databricks during workspace setup (format: service-account@<project>.iam.gserviceaccount.com)."
  nullable    = false
  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.iam\\.gserviceaccount\\.com$", var.databricks_service_account_email))
    error_message = "databricks_service_account_email must be a valid GCP service account email ending in .iam.gserviceaccount.com."
  }
}

variable "kms_key_name" {
  type        = string
  description = "Optional Cloud KMS key resource name for server-side encryption of bucket contents (format: projects/<project>/locations/<location>/keyRings/<keyRing>/cryptoKeys/<key>). null disables CMEK and uses Google-managed encryption."
  default     = null
  nullable    = true
  validation {
    condition     = var.kms_key_name == null || can(regex("^projects/[^/]+/locations/[^/]+/keyRings/[^/]+/cryptoKeys/[^/]+$", var.kms_key_name))
    error_message = "kms_key_name must be null or a fully-qualified KMS key resource name: projects/<project>/locations/<location>/keyRings/<keyRing>/cryptoKeys/<key>."
  }
}

variable "labels" {
  type        = map(string)
  description = "Labels applied to the GCS bucket."
  default     = {}
}

variable "force_destroy" {
  type        = bool
  description = "Allow the bucket to be destroyed even if it contains objects. Set to true for non-production environments."
  default     = false
}

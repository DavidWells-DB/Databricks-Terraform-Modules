variable "credential_name" {
  type        = string
  description = "Name of the Databricks Unity Catalog storage credential. Must be unique within the metastore."
  nullable    = false
  validation {
    # UC storage credential names: conservative bounds — 1-100 chars, alphanumeric + hyphen + underscore.
    # Tighten if Databricks publishes a formal constraint.
    condition     = length(var.credential_name) >= 1 && length(var.credential_name) <= 100 && can(regex("^[A-Za-z0-9_-]+$", var.credential_name))
    error_message = "credential_name must be 1-100 characters and contain only alphanumeric characters, underscores, or hyphens."
  }
}

variable "bucket_name" {
  type        = string
  description = "Name of the GCS bucket to which the Databricks-managed service account is granted storage access. Must be an existing bucket."
  nullable    = false
  validation {
    # GCS bucket name constraints per https://cloud.google.com/storage/docs/buckets#naming:
    # 3-63 characters (standard single-label bucket names), lowercase letters, numbers, hyphens, underscores, dots.
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63 && can(regex("^[a-z0-9][a-z0-9_.\\-]*[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name must be 3-63 characters, start and end with a lowercase letter or digit, and contain only lowercase letters, numbers, hyphens, underscores, or dots."
  }
}

variable "comment" {
  type        = string
  description = "Optional free-text comment for the storage credential. Visible in the Databricks UI and API."
  default     = null
  nullable    = true
}

variable "isolation_mode" {
  type        = string
  description = "Isolation mode for the storage credential. Use ISOLATION_MODE_ISOLATED for regulated environments."
  default     = null
  validation {
    condition     = var.isolation_mode == null || contains(["ISOLATION_MODE_ISOLATED", "ISOLATION_MODE_OPEN"], var.isolation_mode)
    error_message = "isolation_mode must be null, \"ISOLATION_MODE_ISOLATED\", or \"ISOLATION_MODE_OPEN\"."
  }
}

variable "bucket_name" {
  type        = string
  description = "Name of the dedicated GCS bucket for the catalog's managed storage. Globally unique; a common convention is \"<catalog-name>-uc\" with an org suffix."
  nullable    = false
  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 222 && can(regex("^[a-z0-9][a-z0-9._-]*[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name must be 3-222 characters, lowercase letters, numbers, dots, hyphens and underscores, starting and ending with an alphanumeric."
  }
}

variable "location" {
  type        = string
  description = "GCS bucket location — a region (e.g. \"us-east1\"), multi-region (e.g. \"US\"), or dual-region. Should co-locate with the workspace's metastore."
  default     = "US"
}

variable "force_destroy" {
  type        = bool
  description = "Allow the bucket (and all contained objects) to be destroyed by Terraform. Required for clean teardown of scratch deployments; consider false for long-lived data."
  default     = false
}

variable "labels" {
  type        = map(string)
  description = "Labels applied to the bucket. GCP labels: lowercase keys/values, hyphens/underscores allowed."
  default     = {}
}

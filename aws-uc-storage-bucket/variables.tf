variable "bucket_name" {
  type        = string
  description = "Name of the dedicated S3 bucket for the catalog's managed storage. Globally unique across AWS; a common convention is \"<catalog-name>-uc\" with an org suffix."
  nullable    = false
  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63 && can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name must be 3-63 characters, lowercase letters, numbers, dots and hyphens, starting and ending with an alphanumeric."
  }
}

variable "kms_key_arn" {
  type        = string
  description = "Optional KMS key ARN for bucket encryption. Null = SSE-S3 (AES256)."
  default     = null
}

variable "force_destroy" {
  type        = bool
  description = "Allow the bucket (and all contained objects) to be destroyed by Terraform. Required for clean teardown of scratch deployments; consider false for long-lived data."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the bucket."
  default     = {}
}

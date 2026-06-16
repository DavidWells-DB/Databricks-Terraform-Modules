variable "project_id" {
  type        = string
  description = "GCP project ID in which the service account and custom IAM role are created."
  nullable    = false
  validation {
    # GCP project IDs: 6-30 chars, lowercase letters, digits, hyphens, must start with a letter.
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be 6-30 characters, start with a lowercase letter, and contain only lowercase letters, digits, and hyphens."
  }
}

variable "resource_prefix" {
  type        = string
  description = "Prefix applied to the GCP service account ID and custom role ID. Must be lowercase letters, digits, or hyphens, 1-20 characters."
  nullable    = false
  validation {
    # Constrained so the final service account ID (prefix + suffix) stays within GCP's 6-30 char limit.
    condition     = can(regex("^[a-z][a-z0-9-]{0,18}[a-z0-9]$", var.resource_prefix)) || can(regex("^[a-z]$", var.resource_prefix))
    error_message = "resource_prefix must be 1-20 characters, start with a lowercase letter, and contain only lowercase letters, digits, and hyphens."
  }
}

variable "delegate_emails" {
  type        = list(string)
  description = "List of user or service account emails that may impersonate this service account (roles/iam.serviceAccountTokenCreator). Provide fully-qualified emails; service accounts should be prefixed with 'serviceAccount:'."
  default     = []
  nullable    = false
}

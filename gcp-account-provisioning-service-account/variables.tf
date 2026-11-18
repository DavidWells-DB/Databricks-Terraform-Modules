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

variable "service_account_id" {
  type        = string
  description = "Optional provisioning service-account ID. Null derives '<resource_prefix>-dbx-provisioner'."
  default     = null

  validation {
    condition     = var.service_account_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.service_account_id))
    error_message = "service_account_id must be 6-30 lowercase letters, digits, or hyphens and start with a letter."
  }
}

variable "service_account_display_name" {
  type        = string
  description = "Optional service-account display name. Null preserves the prefix-derived display name."
  default     = null
}

variable "custom_role_id" {
  type        = string
  description = "Optional custom IAM role ID. Null preserves the normalized prefix-derived role ID."
  default     = null

  validation {
    condition     = var.custom_role_id == null || can(regex("^[A-Za-z0-9_]{3,64}$", var.custom_role_id))
    error_message = "custom_role_id must contain 3-64 letters, digits, or underscores."
  }
}

variable "custom_role_title" {
  type        = string
  description = "Optional custom IAM role title. Null preserves the prefix-derived title."
  default     = null
}

variable "delegate_emails" {
  type        = list(string)
  description = "List of user or service account emails that may impersonate this service account (roles/iam.serviceAccountTokenCreator). Provide fully-qualified emails; service accounts should be prefixed with 'serviceAccount:'."
  default     = []
  nullable    = false
}

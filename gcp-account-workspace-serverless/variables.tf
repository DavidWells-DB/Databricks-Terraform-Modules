variable "databricks_account_id" {
  type        = string
  description = "Databricks account ID. Used to scope the workspace within the account."
  nullable    = false
  validation {
    # Databricks account IDs are UUIDs.
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.databricks_account_id))
    error_message = "databricks_account_id must be a valid UUID (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)."
  }
}

variable "workspace_name" {
  type        = string
  description = "Human-readable name of the Databricks workspace. Must be unique within the Databricks account."
  nullable    = false
  validation {
    # Conservative bounds matching Databricks API limits: 3-64 chars, alphanumeric + hyphen + underscore.
    condition     = length(var.workspace_name) >= 3 && length(var.workspace_name) <= 64 && can(regex("^[A-Za-z0-9_-]+$", var.workspace_name))
    error_message = "workspace_name must be 3-64 characters and contain only alphanumeric characters, hyphens, or underscores."
  }
}

variable "project_id" {
  type        = string
  description = "GCP project ID in which the serverless workspace is created."
  nullable    = false
  validation {
    # GCP project IDs: 6-30 chars, lowercase letters, digits, hyphens, must start with a letter.
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be 6-30 characters, start with a lowercase letter, and contain only lowercase letters, digits, and hyphens."
  }
}

variable "region" {
  type        = string
  description = "GCP region for the workspace (e.g. \"us-central1\"). Serverless compute runs in Databricks-managed infrastructure in this region."
  nullable    = false
  validation {
    # GCP region names follow the pattern: <geography>-<direction><number> (e.g. us-central1, europe-west4).
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]+$", var.region))
    error_message = "region must be a valid GCP region name (e.g. \"us-central1\", \"europe-west4\")."
  }
}

variable "resource_prefix" {
  type        = string
  description = "Prefix used to derive the workspace deployment name. Must be 1-20 characters, lowercase letters, digits, or hyphens, starting with a letter."
  nullable    = false
  validation {
    # GCP resource names and Databricks deployment names: lowercase alphanumeric and hyphens, must start with a letter.
    # Constrained to 20 chars to leave headroom within the Databricks deployment_name limits.
    condition     = can(regex("^[a-z][a-z0-9-]{0,18}[a-z0-9]$", var.resource_prefix)) || can(regex("^[a-z]$", var.resource_prefix))
    error_message = "resource_prefix must be 1-20 characters, start with a lowercase letter, and contain only lowercase letters, digits, and hyphens."
  }
}

variable "managed_services_key_id" {
  type        = string
  description = "Databricks CMK configuration ID for managed services (notebooks, secrets) encryption. null uses the Databricks-managed key."
  default     = null
}

variable "custom_tags" {
  type        = map(string)
  description = "Tags propagated to workspace-related GCP resources by the Databricks control plane."
  default     = {}
}

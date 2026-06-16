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
  description = "GCP project ID in which the workspace data plane runs."
  nullable    = false
  validation {
    # GCP project IDs: 6-30 chars, lowercase letters, digits, hyphens, must start with a letter.
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be 6-30 characters, start with a lowercase letter, and contain only lowercase letters, digits, and hyphens."
  }
}

variable "region" {
  type        = string
  description = "GCP region for the workspace data plane (e.g. \"us-central1\"). Must match the region of the network and storage configurations."
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

variable "storage_configuration_id" {
  type        = string
  description = "Databricks storage configuration ID produced by the gcp-account-workspace-storage module. Identifies the GCS bucket used as the workspace's root storage."
  nullable    = false
}

variable "databricks_network_id" {
  type        = string
  description = "Databricks network configuration ID produced by the gcp-account-network-vpc module. Identifies the VPC and subnetwork in which workspace compute runs."
  nullable    = false
}

variable "private_access_settings_id" {
  type        = string
  description = "Databricks private access settings ID. When set, enables PSC (Private Service Connect) for the workspace. Produced by the gcp-account-network-psc-endpoints module. null disables PSC."
  default     = null
}

variable "managed_services_key_id" {
  type        = string
  description = "Databricks CMK configuration ID for managed services (notebooks, secrets) encryption. null uses the Databricks-managed key."
  default     = null
}

variable "workspace_storage_key_id" {
  type        = string
  description = "Databricks CMK configuration ID for workspace storage (root GCS bucket) encryption. null uses the Databricks-managed key."
  default     = null
}

variable "custom_tags" {
  type        = map(string)
  description = "Tags propagated to workspace-related GCP resources by the Databricks control plane."
  default     = {}
}

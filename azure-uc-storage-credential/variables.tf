variable "resource_group_name" {
  type        = string
  description = "Name of the Azure resource group in which to create the Access Connector."
  nullable    = false
  validation {
    # Azure resource group name constraint: 1-90 chars, alphanumeric, underscore, hyphen, period.
    # https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules
    condition     = length(var.resource_group_name) >= 1 && length(var.resource_group_name) <= 90 && can(regex("^[A-Za-z0-9_().\\-]+$", var.resource_group_name))
    error_message = "resource_group_name must be 1-90 characters and may only contain alphanumeric characters, underscores, hyphens, parentheses, and periods."
  }
}

variable "location" {
  type        = string
  description = "Azure region for the Access Connector (e.g. \"eastus\", \"westeurope\"). Must match the region of the storage account."
  nullable    = false
  validation {
    # Azure location names are lowercase alphanumeric with no spaces.
    condition     = can(regex("^[a-z][a-z0-9]+$", var.location))
    error_message = "location must be a lowercase Azure region name with no spaces (e.g. \"eastus\", \"westeurope\")."
  }
}

variable "storage_account_id" {
  type        = string
  description = "Full Azure resource ID of the ADLS Gen2 storage account to which Storage Blob Data Contributor will be assigned. Format: /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Storage/storageAccounts/{name}."
  nullable    = false
  validation {
    # Must start with /subscriptions/ and match the Azure storage account ID pattern.
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.Storage/storageAccounts/[^/]+$", var.storage_account_id))
    error_message = "storage_account_id must be a fully-qualified Azure storage account resource ID: /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Storage/storageAccounts/{name}."
  }
}

variable "credential_name" {
  type        = string
  description = "Name for the databricks_storage_credential registration. Must be unique within the Databricks workspace."
  nullable    = false
  validation {
    # No published Databricks constraint; using conservative alphanumeric + hyphen + underscore bounds.
    # 1-100 chars. Tighten if Databricks publishes constraints.
    condition     = length(var.credential_name) >= 1 && length(var.credential_name) <= 100 && can(regex("^[A-Za-z0-9_-]+$", var.credential_name))
    error_message = "credential_name must be 1-100 characters and contain only alphanumeric characters, hyphens, or underscores."
  }
}

variable "access_connector_name" {
  type        = string
  description = "Name of the Azure Databricks Access Connector resource. Defaults to \"dbx-access-connector-<credential_name>\" when null."
  default     = null
  nullable    = true
}

variable "comment" {
  type        = string
  description = "Human-readable comment attached to the databricks_storage_credential. Optional."
  default     = null
  nullable    = true
}

variable "skip_validation" {
  type        = bool
  description = "When true, Databricks skips the automatic credential validation step during storage credential creation. Set to true in environments where validation cannot complete (e.g., locked-down VNets)."
  default     = false
  nullable    = false
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the Azure Databricks Access Connector resource."
  default     = {}
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

variable "name" {
  type        = string
  description = "Name of the Azure Databricks workspace resource. Must be unique within the resource group."
  nullable    = false
  validation {
    # AzureRM name constraint: 3-64 chars, alphanumeric + hyphens; must start/end with alphanumeric.
    # https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules
    condition     = length(var.name) >= 3 && length(var.name) <= 64 && can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.name))
    error_message = "name must be 3-64 characters, alphanumeric and hyphens only, starting and ending with an alphanumeric character."
  }
}

variable "resource_group_id" {
  type        = string
  description = "ARM resource ID of the Azure resource group in which to create the workspace (azapi's parent_id takes the full ID, not the bare name)."
  nullable    = false
  validation {
    condition     = can(regex("^/subscriptions/[a-f0-9-]+/resourceGroups/[a-zA-Z0-9_.()-]+$", var.resource_group_id))
    error_message = "resource_group_id must be a full ARM resource group ID: /subscriptions/<uuid>/resourceGroups/<name>."
  }
}

variable "location" {
  type        = string
  description = "Azure region for the workspace (e.g., \"eastus2\", \"westeurope\"). Must be a region that supports serverless workspaces — see https://learn.microsoft.com/en-us/azure/databricks/resources/feature-region-support."
  nullable    = false
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the Azure Databricks workspace resource."
  default     = {}
}

# Network access

variable "public_network_access_enabled" {
  type        = bool
  description = "Allow public network access to the workspace front-end. Set to false to require private connectivity only (front-end Private Link; the private endpoints themselves are wired by the root composition)."
  default     = true
}

# Customer-managed keys

variable "managed_services_cmk_key_vault_key_id" {
  type        = string
  description = "Versioned Key Vault key identifier (https://<vault>/keys/<name>/<version>) for managed-services encryption — the only customer-managed key legal in a serverless workspace. Omit for platform-managed keys."
  default     = null
  validation {
    condition     = var.managed_services_cmk_key_vault_key_id == null || can(regex("^https://[^/]+/keys/[^/]+/[^/]+$", var.managed_services_cmk_key_vault_key_id))
    error_message = "managed_services_cmk_key_vault_key_id must be a versioned key identifier: https://<vault-host>/keys/<key-name>/<key-version>."
  }
}

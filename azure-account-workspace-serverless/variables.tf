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

variable "resource_group_name" {
  type        = string
  description = "Name of the Azure resource group in which to create the Databricks workspace."
  nullable    = false
}

variable "location" {
  type        = string
  description = "Azure region for the workspace (e.g., \"eastus\", \"westeurope\"). Must match the resource group region."
  nullable    = false
}

variable "sku" {
  type        = string
  description = "Databricks workspace SKU. Use \"premium\" for serverless compute, Unity Catalog, and all Premium features. \"standard\" does not support serverless compute."
  default     = "premium"
  validation {
    condition     = contains(["standard", "premium", "trial"], var.sku)
    error_message = "sku must be \"standard\", \"premium\", or \"trial\"."
  }
}

variable "managed_resource_group_name" {
  type        = string
  description = "Optional name for the managed resource group that Azure Databricks creates for control-plane resources. If null, Azure generates a name automatically."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the Azure Databricks workspace resource."
  default     = {}
}

# Network access

variable "public_network_access_enabled" {
  type        = bool
  description = "Allow public network access to the workspace front-end. Set to false to require private connectivity only (requires private endpoints wired by the root composition)."
  default     = true
}

# Customer-managed keys

variable "managed_services_cmk_key_vault_key_id" {
  type        = string
  description = "Key Vault key ID for managed services (notebooks, artifacts) encryption. Requires customer_managed_key_enabled = true and premium SKU."
  default     = null
}

variable "managed_disk_cmk_key_vault_key_id" {
  type        = string
  description = "Key Vault key ID for managed disk encryption. Requires premium SKU."
  default     = null
}

variable "managed_disk_cmk_rotation_to_latest_version_enabled" {
  type        = bool
  description = "Automatically rotate managed disk CMK to the latest key version. Only relevant when managed_disk_cmk_key_vault_key_id is set."
  default     = false
}

variable "customer_managed_key_enabled" {
  type        = bool
  description = "Enable customer-managed key for managed services encryption. Requires premium SKU and managed_services_cmk_key_vault_key_id."
  default     = false
}

variable "infrastructure_encryption_enabled" {
  type        = bool
  description = "Enable a secondary layer of encryption for workspace data at rest. Requires premium SKU. Immutable after workspace creation."
  default     = false
}

variable "root_dbfs_cmk_key_vault_key_id" {
  type        = string
  description = "Key Vault key ID for root DBFS encryption via azurerm_databricks_workspace_root_dbfs_customer_managed_key. When set, root DBFS CMK is configured as a post-creation step."
  default     = null
}

variable "root_dbfs_cmk_key_vault_id" {
  type        = string
  description = "Resource ID of the Key Vault containing root_dbfs_cmk_key_vault_key_id. Required only when the Key Vault is in a different subscription than the workspace."
  default     = null
}

# Default storage firewall

variable "default_storage_firewall_enabled" {
  type        = bool
  description = "Disallow public access to the default storage account. When true, access_connector_id must also be set."
  default     = false
}

variable "access_connector_id" {
  type        = string
  description = "Resource ID of the Azure Databricks Access Connector. Required when default_storage_firewall_enabled = true."
  default     = null
}

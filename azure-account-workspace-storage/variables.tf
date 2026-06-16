variable "resource_group_name" {
  type        = string
  description = "Name of the Azure resource group in which to create storage resources."
  nullable    = false
}

variable "location" {
  type        = string
  description = "Azure region (e.g. \"eastus\", \"westeurope\") for all resources."
  nullable    = false
}

variable "resource_prefix" {
  type        = string
  description = "Prefix applied to all resource names. Must be 1-16 characters, lowercase alphanumeric only. Combined with fixed suffixes to form the storage account name (max 24 chars total)."
  nullable    = false
  validation {
    # Azure storage account names must be 3-24 chars, lowercase alphanumeric only.
    # The module appends "stor" (4 chars) to this prefix, so the prefix itself is
    # capped at 20 chars; here we cap at 16 to leave headroom for uniqueness suffixes.
    condition     = length(var.resource_prefix) >= 1 && length(var.resource_prefix) <= 16 && can(regex("^[a-z0-9]+$", var.resource_prefix))
    error_message = "resource_prefix must be 1-16 characters, lowercase alphanumeric only (no hyphens, underscores, or uppercase)."
  }
}

variable "container_name" {
  type        = string
  description = "Name of the ADLS Gen2 container (filesystem) to create inside the storage account. Defaults to \"databricks\" when null."
  default     = null
  nullable    = true
  validation {
    # Azure container names: 3-63 chars, lowercase alphanumeric and hyphens, no double hyphens,
    # must not start or end with a hyphen.
    # https://learn.microsoft.com/en-us/rest/api/storageservices/naming-and-referencing-containers--blobs--and-metadata
    condition     = var.container_name == null || (length(var.container_name) >= 3 && length(var.container_name) <= 63 && can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.container_name)) && !can(regex("--", var.container_name)))
    error_message = "container_name must be 3-63 characters, lowercase alphanumeric and hyphens, must not start or end with a hyphen, and must not contain consecutive hyphens."
  }
}

variable "kms_key_id" {
  type        = string
  description = "Resource ID of an Azure Key Vault key to use for customer-managed encryption (CMK). When null, Microsoft-managed keys are used. Required for Azure Government IL5 deployments."
  default     = null
  nullable    = true
}

variable "account_tier" {
  type        = string
  description = "Azure storage account tier. Use \"Standard\" for most workloads; \"Premium\" for latency-sensitive scenarios."
  default     = "Standard"
  nullable    = false
  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "account_tier must be \"Standard\" or \"Premium\"."
  }
}

variable "account_replication_type" {
  type        = string
  description = "Replication type for the storage account (LRS, GRS, ZRS, GZRS, RA-GRS, RA-GZRS). LRS is the minimum required for Databricks; choose based on your DR requirements."
  default     = "LRS"
  nullable    = false
  validation {
    condition     = contains(["LRS", "GRS", "ZRS", "GZRS", "RA-GRS", "RA-GZRS"], var.account_replication_type)
    error_message = "account_replication_type must be one of: LRS, GRS, ZRS, GZRS, RA-GRS, RA-GZRS."
  }
}

variable "min_tls_version" {
  type        = string
  description = "Minimum TLS version enforced on the storage account. Databricks recommends TLS 1.2 or higher."
  default     = "TLS1_2"
  nullable    = false
  validation {
    condition     = contains(["TLS1_0", "TLS1_1", "TLS1_2"], var.min_tls_version)
    error_message = "min_tls_version must be one of: TLS1_0, TLS1_1, TLS1_2."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all Azure resources created by this module."
  default     = {}
}

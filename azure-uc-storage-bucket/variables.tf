variable "storage_account_name" {
  type        = string
  description = "Name of the dedicated ADLS Gen2 storage account. Globally unique across Azure, lowercase alphanumeric, 3-24 chars. A common convention is \"<catalog-name-without-underscores>ucst\"."
  nullable    = false
  validation {
    condition     = length(var.storage_account_name) >= 3 && length(var.storage_account_name) <= 24 && can(regex("^[a-z0-9]+$", var.storage_account_name))
    error_message = "storage_account_name must be 3-24 characters, lowercase letters and numbers only (Azure storage account naming rules)."
  }
}

variable "container_name" {
  type        = string
  description = "Name of the dedicated container for the catalog's managed data."
  default     = "catalog"
  nullable    = false
  validation {
    condition     = length(var.container_name) >= 3 && length(var.container_name) <= 63 && can(regex("^[a-z0-9][a-z0-9-]*$", var.container_name))
    error_message = "container_name must be 3-63 characters, lowercase letters, numbers and hyphens, starting alphanumeric."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Name of the Azure resource group for the storage account."
  nullable    = false
}

variable "location" {
  type        = string
  description = "Azure region for the storage account (e.g. \"eastus\")."
  nullable    = false
}

variable "account_tier" {
  type        = string
  description = "Storage account tier. \"Standard\" for catalog managed storage."
  default     = "Standard"
  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "account_tier must be \"Standard\" or \"Premium\"."
  }
}

variable "account_replication_type" {
  type        = string
  description = "Replication type for the storage account (LRS / ZRS / GRS / GZRS)."
  default     = "LRS"
  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "GZRS"], var.account_replication_type)
    error_message = "account_replication_type must be one of LRS, ZRS, GRS, GZRS."
  }
}

variable "min_tls_version" {
  type        = string
  description = "Minimum TLS version for the storage account."
  default     = "TLS1_2"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the storage account."
  default     = {}
}

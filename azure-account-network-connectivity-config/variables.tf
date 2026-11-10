variable "databricks_account_id" {
  type        = string
  description = "Databricks account ID. Required by the account-level provider."
  nullable    = false
}

variable "name" {
  type        = string
  description = "Name for the Network Connectivity Config. Must be 3-30 characters and contain only alphanumeric characters, hyphens, or underscores."
  nullable    = false
  validation {
    # Constraint documented by the Databricks provider: ^[0-9a-zA-Z-_]{3,30}$
    condition     = can(regex("^[0-9a-zA-Z_-]{3,30}$", var.name))
    error_message = "name must be 3-30 characters and contain only alphanumeric characters, hyphens, or underscores."
  }
}

variable "region" {
  type        = string
  description = "Azure region where the NCC will be created. Must match the region of the workspaces that will use it (e.g., \"eastus\", \"westeurope\"). NCCs can only be associated with workspaces in the same region."
  nullable    = false
}

variable "allowed_internet_destinations" {
  type = list(object({
    destination               = string
    internet_destination_type = string
  }))
  description = "REMOVED in v0.2.0 (single-owner consolidation): the account network policy is owned solely by dbx-account-network-policy (or the azure-account-network-foundation composition). Keep null; create the policy there and pass its ID to the binding module."
  default     = null
  nullable    = true
  validation {
    condition     = var.allowed_internet_destinations == null
    error_message = "allowed_internet_destinations is no longer accepted here: the account network policy is owned by dbx-account-network-policy (see also azure-account-network-foundation for the one-call NCC+policy surface)."
  }
}

variable "network_policy_id" {
  type        = string
  description = "REMOVED in v0.2.0 (single-owner consolidation, see allowed_internet_destinations). Keep null."
  default     = null
  nullable    = true
  validation {
    condition     = var.network_policy_id == null
    error_message = "network_policy_id is no longer accepted here: the account network policy is owned by dbx-account-network-policy (see also azure-account-network-foundation)."
  }
}

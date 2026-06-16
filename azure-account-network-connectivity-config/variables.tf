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
  description = "List of internet destinations to allow when the account network policy is in RESTRICTED_ACCESS mode. Each entry requires a destination (DNS name) and internet_destination_type (currently only \"DNS_NAME\" is supported). When null, no account network policy is created and no internet restrictions are applied."
  default     = null
  nullable    = true
  validation {
    condition = var.allowed_internet_destinations == null || alltrue([
      for d in var.allowed_internet_destinations : contains(["DNS_NAME"], d.internet_destination_type)
    ])
    error_message = "Each allowed_internet_destinations entry must have internet_destination_type = \"DNS_NAME\"."
  }
}

variable "network_policy_id" {
  type        = string
  description = "ID for the account network policy. Required when allowed_internet_destinations is set. Must be unique within the Databricks account."
  default     = null
  nullable    = true
}

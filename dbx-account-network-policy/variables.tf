variable "databricks_account_id" {
  type        = string
  description = "Databricks account ID. Set explicitly on the policy so the provider does not treat it as computed (which forces replacement on every plan)."
  nullable    = false
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.databricks_account_id))
    error_message = "databricks_account_id must be a UUID."
  }
}

variable "policy_name" {
  type        = string
  description = "Name for the network policy. Must be unique within the Databricks account."
  nullable    = false
  validation {
    # Network policy name constraint: 1-32 chars, alphanumeric + hyphens per
    # https://docs.databricks.com/security/network/serverless-network-policy.html
    condition     = length(var.policy_name) >= 1 && length(var.policy_name) <= 32 && can(regex("^[A-Za-z0-9-]+$", var.policy_name))
    error_message = "policy_name must be 1-32 characters and contain only alphanumeric characters or hyphens."
  }
}

variable "egress_mode" {
  type        = string
  description = "Egress restriction mode for serverless compute, mapped to the provider's `restriction_mode`. \"RESTRICTED_ACCESS\" allows only the listed destinations; \"FULL_ACCESS\" allows all internet egress."
  default     = "RESTRICTED_ACCESS"
  nullable    = false
  validation {
    # These are the only values the databricks provider accepts for
    # egress.network_access.restriction_mode. Passing anything else crashes the provider.
    condition     = contains(["RESTRICTED_ACCESS", "FULL_ACCESS"], var.egress_mode)
    error_message = "egress_mode must be \"RESTRICTED_ACCESS\" or \"FULL_ACCESS\"."
  }
}

variable "allowed_internet_destinations" {
  type = list(object({
    destination               = string
    internet_destination_type = optional(string, "DNS_NAME")
  }))
  description = "Internet destinations allowed when egress_mode is RESTRICTED_ACCESS. Each entry has a 'destination' (a domain name) and 'internet_destination_type' (only \"DNS_NAME\" is currently supported by the provider; IP_RANGE is planned but not yet available)."
  default     = []
  nullable    = false
  validation {
    condition     = alltrue([for d in var.allowed_internet_destinations : contains(["DNS_NAME"], coalesce(d.internet_destination_type, "DNS_NAME"))])
    error_message = "internet_destination_type must be \"DNS_NAME\" (the only value the provider currently supports)."
  }
}

variable "allowed_storage_destinations" {
  type = list(object({
    bucket_name              = optional(string)
    azure_storage_account    = optional(string)
    azure_storage_service    = optional(string)
    region                   = optional(string)
    storage_destination_type = optional(string)
  }))
  description = "Storage targets accessible from serverless compute. For AWS, specify 'bucket_name' and optionally 'region'; for Azure, specify 'azure_storage_account' and optionally 'azure_storage_service'. Optionally include 'storage_destination_type'."
  default     = []
  nullable    = false
}

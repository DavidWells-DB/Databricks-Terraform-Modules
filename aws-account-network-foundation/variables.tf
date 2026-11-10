variable "databricks_account_id" {
  type        = string
  description = "Databricks account ID. Required by the account network policy (the NCC itself infers it from the provider)."
  nullable    = false
}

variable "region" {
  type        = string
  description = "AWS region. The NCC can only be referenced by workspaces in the same region."
  nullable    = false
}

variable "ncc_name" {
  type        = string
  description = "Name for the Network Connectivity Config (3-30 chars, alphanumeric/hyphens/underscores)."
  nullable    = false
  # Self-guard (mirrors the NCC owner module's rule) so the composition's own surface is
  # plan-time testable — child-module variable failures are not addressable in tests.
  validation {
    condition     = can(regex("^[0-9a-zA-Z_-]{3,30}$", var.ncc_name))
    error_message = "ncc_name must be 3-30 characters containing only alphanumeric characters, hyphens, or underscores."
  }
}

variable "create_policy" {
  type        = bool
  description = "Create the account network policy alongside the NCC. false = NCC only (serverless compute unrestricted). The policy is the RESTRICTED_ACCESS egress control surface."
  default     = false
}

variable "policy_name" {
  type        = string
  description = "Name (network_policy_id) for the account network policy. Only used when create_policy = true."
  default     = "serverless-egress"
}

variable "egress_mode" {
  type        = string
  description = "Restriction mode: \"RESTRICTED_ACCESS\" (allow-list) or \"FULL_ACCESS\". Only used when create_policy = true."
  default     = "RESTRICTED_ACCESS"
  # Self-guard (mirrors the policy owner module's rule) — see ncc_name's note.
  validation {
    condition     = contains(["RESTRICTED_ACCESS", "FULL_ACCESS"], var.egress_mode)
    error_message = "egress_mode must be \"RESTRICTED_ACCESS\" or \"FULL_ACCESS\"."
  }
}

variable "enforcement_mode" {
  type        = string
  description = "Enforcement: \"ENFORCED\" or \"MONITORED\" (dry-run). Only used when create_policy = true."
  default     = "ENFORCED"
}

variable "allowed_internet_destinations" {
  type = list(object({
    destination               = string
    internet_destination_type = string
  }))
  description = "Internet allow-list entries ({destination, internet_destination_type=\"DNS_NAME\"}). Only used when create_policy = true with RESTRICTED_ACCESS."
  default     = []
}

variable "allowed_storage_destinations" {
  type = list(object({
    bucket_name           = string
    azure_storage_account = optional(string)
    azure_container       = optional(string)
  }))
  description = "Storage allow-list entries ({bucket_name} on AWS; Azure fields unused there). Only used when create_policy = true with RESTRICTED_ACCESS."
  default     = []
}

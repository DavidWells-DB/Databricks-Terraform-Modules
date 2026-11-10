variable "databricks_account_id" {
  type        = string
  description = "Databricks account ID. Required by the account-level registration."
  nullable    = false
}

variable "vpc_id" {
  type        = string
  description = "The customer VPC ID to register (from aws-account-vpc, or your own)."
  nullable    = false
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for Databricks compute (from aws-account-vpc, or your own)."
  nullable    = false
  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "At least two private subnet IDs are required (Databricks workspace VPC requirements)."
  }
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security group IDs for the registration (the Databricks-required SG from aws-account-vpc, or your own)."
  nullable    = false
}

variable "network_name" {
  type        = string
  description = "Base name for the databricks_mws_networks registration(s). Should be descriptive and unique within the Databricks account. When PrivateLink is enabled a second registration named \"<network_name>-privatelink\" is created alongside it, so this is capped to leave room for that 12-char suffix."
  nullable    = false
  validation {
    # Capped at 88 (not 100) so the derived "<name>-privatelink" registration stays <= 100 chars.
    condition     = length(var.network_name) >= 1 && length(var.network_name) <= 88 && can(regex("^[A-Za-z0-9_-]+$", var.network_name))
    error_message = "network_name must be 1-88 characters, alphanumeric/underscores/hyphens only."
  }
}

variable "enable_privatelink" {
  type        = bool
  description = "Whether to register the additional back-end PrivateLink network config (named \"<network_name>-privatelink\") alongside the retained base config. This is the PLAN-TIME-KNOWN switch that decides the set of network registrations; keep it separate from vpc_endpoint_ids, whose values are typically known only after apply (they come from endpoints created in the same run). Setting it true without vpc_endpoint_ids registers the PrivateLink config without the vpc_endpoints block."
  default     = false
  nullable    = false
}

variable "vpc_endpoint_ids" {
  type = object({
    relay_id    = optional(string)
    rest_api_id = optional(string)
  })
  description = "Optional PrivateLink VPC endpoint IDs from aws-account-network-privatelink-endpoints. Supplies the vpc_endpoints block ON the PrivateLink registration (see enable_privatelink). Values may be known only after apply; that is fine because enable_privatelink — not this — determines the resource key set. Set to null to omit the vpc_endpoints block."
  default     = null
}

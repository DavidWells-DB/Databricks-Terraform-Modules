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
  description = "Egress restriction mode for serverless compute. Use \"ALLOW_LIST\" to restrict egress to allowed destinations; \"UNRESTRICTED\" to allow all internet egress."
  default     = "ALLOW_LIST"
  nullable    = false
  validation {
    condition     = contains(["ALLOW_LIST", "UNRESTRICTED"], var.egress_mode)
    error_message = "egress_mode must be \"ALLOW_LIST\" or \"UNRESTRICTED\"."
  }
}

variable "allowed_internet_destinations" {
  type = list(object({
    destination               = string
    internet_destination_type = optional(string)
  }))
  description = "Internet destinations (CIDR blocks or FQDNs) allowed when egress_mode is ALLOW_LIST. Each object must have 'destination' (CIDR or FQDN) and optionally 'internet_destination_type' (CIDR or FQDN)."
  default     = []
  nullable    = false
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

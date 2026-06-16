variable "allow_list_label" {
  type        = string
  description = "Human-readable label for the ALLOW IP access list entry. Displayed in the Databricks workspace security settings UI."
  nullable    = false
  default     = "allow-list"
  validation {
    # Conservative bounds: 1-255 chars matching printable non-whitespace sequences.
    condition     = length(var.allow_list_label) >= 1 && length(var.allow_list_label) <= 255
    error_message = "allow_list_label must be between 1 and 255 characters."
  }
}

variable "allow_list_cidrs" {
  type        = list(string)
  description = "List of IPv4 CIDR blocks or individual IP addresses permitted to reach the workspace. At least one entry is required. Example: [\"10.0.0.0/8\", \"203.0.113.42\"]."
  nullable    = false
  validation {
    condition     = length(var.allow_list_cidrs) >= 1
    error_message = "allow_list_cidrs must contain at least one IP address or CIDR block."
  }
  validation {
    # Each entry must be a dotted-decimal IPv4 address or CIDR (basic format check).
    condition = alltrue([
      for cidr in var.allow_list_cidrs :
      can(regex("^(\\d{1,3}\\.){3}\\d{1,3}(/\\d{1,2})?$", cidr))
    ])
    error_message = "Each entry in allow_list_cidrs must be a valid IPv4 address or CIDR (e.g. \"10.0.0.0/8\" or \"203.0.113.42\")."
  }
}

variable "block_list_cidrs" {
  type        = list(string)
  description = "Optional list of IPv4 CIDR blocks or individual IP addresses explicitly denied workspace access. Entries in the block list take precedence over the allow list. null or empty list means no block list is created."
  default     = null
  nullable    = true
  validation {
    condition = var.block_list_cidrs == null || (
      length(var.block_list_cidrs) >= 1 &&
      alltrue([
        for cidr in var.block_list_cidrs :
        can(regex("^(\\d{1,3}\\.){3}\\d{1,3}(/\\d{1,2})?$", cidr))
      ])
    )
    error_message = "block_list_cidrs, when provided, must be a non-empty list and each entry must be a valid IPv4 address or CIDR (e.g. \"10.0.0.0/8\" or \"203.0.113.42\")."
  }
}

variable "block_list_label" {
  type        = string
  description = "Human-readable label for the BLOCK IP access list entry. Only used when block_list_cidrs is non-null."
  nullable    = false
  default     = "block-list"
  validation {
    condition     = length(var.block_list_label) >= 1 && length(var.block_list_label) <= 255
    error_message = "block_list_label must be between 1 and 255 characters."
  }
}

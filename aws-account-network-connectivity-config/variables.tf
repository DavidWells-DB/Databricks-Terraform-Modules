variable "region" {
  type        = string
  description = "AWS region for the Network Connectivity Configuration. NCCs can only be referenced by workspaces in the same region. Forces replacement on change."
  nullable    = false
  validation {
    # AWS region names follow the pattern: <area>-<direction>-<number> (e.g., us-east-1, eu-west-2).
    # GovCloud regions: us-gov-east-1, us-gov-west-1.
    condition     = can(regex("^[a-z]+-[a-z]+-[0-9]+$|^[a-z]+-gov-[a-z]+-[0-9]+$", var.region))
    error_message = "region must be a valid AWS region name (e.g., \"us-east-1\", \"us-gov-west-1\")."
  }
}

variable "name" {
  type        = string
  description = "Name for the Network Connectivity Configuration. Must be 3-30 characters: alphanumeric, hyphens, or underscores. Forces replacement on change."
  nullable    = false
  validation {
    # Databricks-documented constraint for NCC name:
    # https://docs.databricks.com/api/account/networkconnectivity/create
    condition     = can(regex("^[0-9a-zA-Z_-]{3,30}$", var.name))
    error_message = "name must be 3-30 characters containing only alphanumeric characters, hyphens, or underscores."
  }
}

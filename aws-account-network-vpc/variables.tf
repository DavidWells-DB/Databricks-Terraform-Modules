variable "databricks_account_id" {
  type        = string
  description = "Databricks account ID. Used to register the network configuration with the Databricks account API."
  nullable    = false
}

variable "databricks_gov_shard" {
  type        = string
  description = "Databricks GovCloud shard. null for commercial; \"civilian\" for AWS GovCloud civilian (FedRAMP High); \"dod\" for IL5/DoD."
  default     = null
  validation {
    condition     = var.databricks_gov_shard == null || contains(["civilian", "dod"], var.databricks_gov_shard)
    error_message = "databricks_gov_shard must be null, \"civilian\", or \"dod\"."
  }
}

variable "resource_prefix" {
  type        = string
  description = "Prefix used to name all created resources (VPC, subnets, security group, route tables). Must be 1-32 characters, alphanumeric and hyphens only."
  nullable    = false
  validation {
    condition     = length(var.resource_prefix) >= 1 && length(var.resource_prefix) <= 32 && can(regex("^[A-Za-z0-9-]+$", var.resource_prefix))
    error_message = "resource_prefix must be 1-32 characters containing only alphanumeric characters and hyphens."
  }
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC. Must be a valid IPv4 CIDR (e.g. \"10.0.0.0/16\"). Databricks requires a minimum /16 for the workspace VPC."
  nullable    = false
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block (e.g. \"10.0.0.0/16\")."
  }
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks for private subnets. Must provide at least two subnets (one per AZ) for Databricks HA. Each CIDR must be a valid subnet of vpc_cidr."
  nullable    = false
  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "private_subnet_cidrs must contain at least 2 entries (one per availability zone for high availability)."
  }
  validation {
    condition     = alltrue([for cidr in var.private_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "All entries in private_subnet_cidrs must be valid IPv4 CIDR blocks."
  }
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Optional list of CIDR blocks for public subnets. Leave empty to skip public subnet creation. Required if deploying NAT gateways or internet-facing resources."
  default     = []
  nullable    = false
  validation {
    condition     = alltrue([for cidr in var.public_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "All entries in public_subnet_cidrs must be valid IPv4 CIDR blocks."
  }
}

variable "privatelink_subnet_cidrs" {
  type        = list(string)
  description = "Optional list of CIDR blocks for PrivateLink-dedicated subnets. Leave empty to skip PrivateLink subnet creation. Required when deploying aws-account-network-privatelink-endpoints."
  default     = []
  nullable    = false
  validation {
    condition     = alltrue([for cidr in var.privatelink_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "All entries in privatelink_subnet_cidrs must be valid IPv4 CIDR blocks."
  }
}

variable "azs" {
  type        = list(string)
  description = "List of availability zone names (e.g. [\"us-east-1a\", \"us-east-1b\"]). Must have the same length as private_subnet_cidrs. Also used for public and PrivateLink subnets when those lists are non-empty."
  nullable    = false
  validation {
    condition     = length(var.azs) >= 2
    error_message = "azs must contain at least 2 entries for high availability."
  }
  validation {
    # Matches commercial AZs (e.g. us-east-1a) and GovCloud AZs (e.g. us-gov-west-1a, us-gov-east-1b).
    condition     = alltrue([for az in var.azs : can(regex("^[a-z]{2}-(?:gov-)?[a-z]+-[0-9][a-z]$", az))])
    error_message = "Each entry in azs must be a valid AWS availability zone name (e.g. \"us-east-1a\" or \"us-gov-west-1a\")."
  }
}

variable "vpc_endpoint_ids" {
  type = object({
    rest_api_id = optional(string)
    relay_id    = optional(string)
  })
  description = "Optional PrivateLink VPC endpoint IDs from aws-account-network-privatelink-endpoints. When provided, wired into the databricks_mws_networks registration to enable PrivateLink connectivity. Set to null to skip PrivateLink wiring."
  default     = null
}

variable "network_name" {
  type        = string
  description = "Name for the databricks_mws_networks registration. Should be descriptive and unique within the Databricks account."
  nullable    = false
  validation {
    # No public Databricks-documented constraint; using conservative common-sense bounds.
    # 1-100 chars, alphanumeric + hyphen + underscore. Tighten if Databricks publishes constraints.
    condition     = length(var.network_name) >= 1 && length(var.network_name) <= 100 && can(regex("^[A-Za-z0-9_-]+$", var.network_name))
    error_message = "network_name must be 1-100 characters and contain only alphanumeric, underscore, or hyphen."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all AWS resources created by this module."
  default     = {}
}

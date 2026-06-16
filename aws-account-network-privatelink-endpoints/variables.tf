variable "databricks_gov_shard" {
  type        = string
  description = "Databricks GovCloud shard. null for commercial; \"civilian\" for AWS GovCloud civilian (FedRAMP High); \"dod\" for IL5/DoD. Drives the endpoint service attachment URIs and account host URL."
  default     = null
  validation {
    condition     = var.databricks_gov_shard == null || contains(["civilian", "dod"], var.databricks_gov_shard)
    error_message = "databricks_gov_shard must be null, \"civilian\", or \"dod\"."
  }
}

variable "vpc_id" {
  type        = string
  description = "ID of the AWS VPC in which to create the PrivateLink interface endpoints."
  nullable    = false
  validation {
    condition     = can(regex("^vpc-[0-9a-f]+$", var.vpc_id))
    error_message = "vpc_id must be a valid VPC ID in the format vpc-<hex>."
  }
}

variable "privatelink_subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs in which to place the PrivateLink interface endpoint ENIs. Must be in the same VPC as vpc_id. At least one subnet is required; one per availability zone is recommended."
  nullable    = false
  validation {
    condition     = length(var.privatelink_subnet_ids) >= 1
    error_message = "privatelink_subnet_ids must contain at least one subnet ID."
  }
  validation {
    condition     = alltrue([for s in var.privatelink_subnet_ids : can(regex("^subnet-[0-9a-f]+$", s))])
    error_message = "Every entry in privatelink_subnet_ids must be a valid subnet ID in the format subnet-<hex>."
  }
}

variable "region" {
  type        = string
  description = "AWS region where the VPC and endpoints reside (e.g. \"us-east-1\"). Used to look up the Databricks endpoint service attachment URIs and to register endpoints with the Databricks account API."
  nullable    = false
  validation {
    condition     = can(regex("^[a-z]{2,}(-[a-z]+)+-[0-9]+$", var.region))
    error_message = "region must be a valid AWS region name (e.g. \"us-east-1\", \"eu-west-2\", \"us-gov-west-1\")."
  }
}

variable "private_access_settings_name" {
  type        = string
  description = "Display name for the databricks_mws_private_access_settings object. Must be unique within the Databricks account."
  nullable    = false
  validation {
    condition     = length(var.private_access_settings_name) >= 1 && length(var.private_access_settings_name) <= 100
    error_message = "private_access_settings_name must be between 1 and 100 characters."
  }
}

variable "workspace_vpc_endpoint_name" {
  type        = string
  description = "Display name for the workspace (REST API) databricks_mws_vpc_endpoint registration. Must be unique within the Databricks account."
  nullable    = false
  validation {
    condition     = length(var.workspace_vpc_endpoint_name) >= 1 && length(var.workspace_vpc_endpoint_name) <= 100
    error_message = "workspace_vpc_endpoint_name must be between 1 and 100 characters."
  }
}

variable "relay_vpc_endpoint_name" {
  type        = string
  description = "Display name for the SCC relay databricks_mws_vpc_endpoint registration. Must be unique within the Databricks account."
  nullable    = false
  validation {
    condition     = length(var.relay_vpc_endpoint_name) >= 1 && length(var.relay_vpc_endpoint_name) <= 100
    error_message = "relay_vpc_endpoint_name must be between 1 and 100 characters."
  }
}

variable "public_access_enabled" {
  type        = bool
  description = "Whether the Databricks workspace can also be accessed over the public internet. true allows both public and PrivateLink access; false restricts access to PrivateLink only. Defaults to false (PrivateLink-only)."
  default     = false
}

variable "private_access_level" {
  type        = string
  description = "Controls which VPC endpoints may connect to workspaces that use this Private Access Settings object. \"ACCOUNT\" (default) allows all VPC endpoints registered in the account; \"ENDPOINT\" restricts to the list in allowed_vpc_endpoint_ids."
  default     = "ACCOUNT"
  validation {
    condition     = contains(["ACCOUNT", "ENDPOINT"], var.private_access_level)
    error_message = "private_access_level must be \"ACCOUNT\" or \"ENDPOINT\"."
  }
}

variable "allowed_vpc_endpoint_ids" {
  type        = list(string)
  description = "List of databricks_mws_vpc_endpoint IDs allowed to connect when private_access_level = \"ENDPOINT\". Ignored when private_access_level = \"ACCOUNT\"."
  default     = []
  nullable    = false
}

variable "enable_service_direct" {
  type        = bool
  description = "Whether to create a third AWS VPC endpoint for the Databricks service-direct (frontend) PrivateLink service. Not available in GovCloud shards — set to false when databricks_gov_shard is non-null."
  default     = false
}

variable "service_direct_vpc_endpoint_name" {
  type        = string
  description = "Display name for the service-direct databricks_mws_vpc_endpoint registration. Only used when enable_service_direct = true."
  default     = null
}

variable "custom_service_attachment_uris" {
  type = object({
    workspace      = optional(string)
    relay          = optional(string)
    service_direct = optional(string)
  })
  description = "Override the module-computed Databricks endpoint service attachment URIs for the workspace, relay, and service-direct endpoints. Use when your region is not in the module's built-in map or when Databricks publishes updated URIs."
  default     = {}
}

variable "security_group_name" {
  type        = string
  description = "Name for the AWS security group created to control traffic to the PrivateLink interface endpoints."
  nullable    = false
  validation {
    condition     = length(var.security_group_name) >= 1 && length(var.security_group_name) <= 255
    error_message = "security_group_name must be between 1 and 255 characters."
  }
}

variable "security_group_ingress_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks permitted to reach the PrivateLink endpoints. Typically the VPC CIDR and any workspace subnet CIDRs. Ports 443, 2443 (FIPS/CSP), and 6666 (SCC relay) are opened for these blocks."
  nullable    = false
  validation {
    condition     = length(var.security_group_ingress_cidr_blocks) >= 1
    error_message = "security_group_ingress_cidr_blocks must contain at least one CIDR block."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all AWS resources created by this module (security group and VPC endpoints)."
  default     = {}
}

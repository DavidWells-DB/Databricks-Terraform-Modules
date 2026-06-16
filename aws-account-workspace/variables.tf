variable "databricks_account_id" {
  type        = string
  description = "Databricks account ID. Used to scope the workspace within the account."
  nullable    = false
}

variable "workspace_name" {
  type        = string
  description = "Human-readable name of the Databricks workspace. Must be unique within the Databricks account."
  nullable    = false
  validation {
    # Conservative bounds matching Databricks API limits: 3-64 chars, alphanumeric + hyphen + underscore.
    condition     = length(var.workspace_name) >= 3 && length(var.workspace_name) <= 64 && can(regex("^[A-Za-z0-9_-]+$", var.workspace_name))
    error_message = "workspace_name must be 3-64 characters and contain only alphanumeric characters, hyphens, or underscores."
  }
}

variable "region" {
  type        = string
  description = "AWS region in which the workspace is deployed (e.g. \"us-east-1\")."
  nullable    = false
  validation {
    # Standard AWS region pattern: 2-3 lowercase word segments separated by hyphens, ending in a digit.
    condition     = can(regex("^[a-z]{2,}-[a-z]+-[0-9]$", var.region))
    error_message = "region must be a valid AWS region string, e.g. \"us-east-1\", \"us-gov-west-1\"."
  }
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

variable "credentials_id" {
  type        = string
  description = "Databricks credentials object ID produced by the aws-account-workspace-credentials module. Grants the control plane permission to manage compute in the customer AWS account."
  nullable    = false
}

variable "storage_configuration_id" {
  type        = string
  description = "Databricks storage configuration ID produced by the aws-account-workspace-storage module. Identifies the S3 bucket used as the workspace's DBFS root."
  nullable    = false
}

variable "databricks_network_id" {
  type        = string
  description = "Databricks network configuration ID produced by the aws-account-network module. Identifies the VPC and subnets in which workspace compute runs."
  nullable    = false
}

variable "private_access_settings_id" {
  type        = string
  description = "Databricks private access settings ID. When set, enables PrivateLink for the workspace. Produced by the aws-account-network-privatelink module. null disables PrivateLink."
  default     = null
}

variable "managed_services_key_id" {
  type        = string
  description = "Databricks CMK configuration ID for managed services (notebooks, secrets) encryption. null uses the Databricks-managed key."
  default     = null
}

variable "workspace_storage_key_id" {
  type        = string
  description = "Databricks CMK configuration ID for workspace storage (DBFS root) encryption. null uses the Databricks-managed key."
  default     = null
}

variable "network_connectivity_config_id" {
  type        = string
  description = "Databricks network connectivity configuration (NCC) ID. When set, binds the NCC to this workspace for serverless or Databricks-managed network egress. null skips NCC binding."
  default     = null
}

variable "custom_tags" {
  type        = map(string)
  description = "Tags propagated to workspace-related cloud resources by the Databricks control plane."
  default     = {}
}

variable "databricks_account_id" {
  type        = string
  description = "Databricks account ID. Must match the account_id used by the databricks.account provider."
  nullable    = false
}

variable "workspace_name" {
  type        = string
  description = "Display name for the workspace in the Databricks UI. Must be unique within the Databricks account."
  nullable    = false
  validation {
    # Conservative bounds; Databricks has not published a formal character limit.
    # Tighten if Databricks documents constraints.
    condition     = length(var.workspace_name) >= 1 && length(var.workspace_name) <= 64 && can(regex("^[A-Za-z0-9_-]+$", var.workspace_name))
    error_message = "workspace_name must be 1-64 characters and contain only alphanumeric, underscore, or hyphen characters."
  }
}

variable "region" {
  type        = string
  description = "AWS region in which to create the serverless workspace (e.g. \"us-east-1\", \"us-gov-west-1\")."
  nullable    = false
  validation {
    # AWS region names: lowercase letters, digits, hyphens; multiple hyphen-separated segments
    # followed by a numeric availability zone (e.g. "us-east-1", "eu-west-2", "us-gov-west-1").
    condition     = can(regex("^[a-z][a-z0-9-]+-[0-9]+$", var.region))
    error_message = "region must be a valid AWS region name (e.g. \"us-east-1\", \"eu-west-2\", \"us-gov-west-1\")."
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


# Retained to reject the removed input with a useful migration error.
# tflint-ignore: terraform_unused_declarations
variable "network_connectivity_config_id" {
  type        = string
  description = "REMOVED in v0.5.0 (single-owner consolidation): NCC binding is owned solely by dbx-workspace-network-serverless. Keep null; bind the NCC there instead."
  default     = null
  nullable    = true
  validation {
    condition     = var.network_connectivity_config_id == null
    error_message = "network_connectivity_config_id is no longer accepted here: bind the NCC via the dbx-workspace-network-serverless module (the sole owner of databricks_mws_ncc_binding)."
  }
}

variable "deployment_name" {
  type        = string
  description = "Optional. URL prefix component for the workspace host (e.g. \"my-ws\" produces \"my-ws.cloud.databricks.com\"). Leave null to let Databricks auto-assign."
  default     = null
}

variable "managed_services_key_id" {
  type        = string
  description = "Databricks customer-managed-key configuration ID for managed services. Do not set during the workspace's first apply: the account API accepts this field only as a post-create update, not in the SERVERLESS create body. Use the key configuration ID, not the KMS ARN."
  default     = null
}

variable "custom_tags" {
  type        = map(string)
  description = "Optional. Key-value tags applied to clusters launched in this workspace. Note: tags set here may be overridden by humans in the Databricks UI; this field is ignored on plan after initial creation (see lifecycle ignore_changes comment in main.tf)."
  default     = {}
}


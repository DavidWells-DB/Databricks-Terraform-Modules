variable "databricks_account_id" {
  type        = string
  description = "Databricks account ID. Used as the external ID in the IAM role's assume-role policy and in the storage configuration registration."
  nullable    = false
}

variable "aws_partition" {
  type        = string
  description = "AWS partition for ARN construction. Use \"aws\" for commercial; \"aws-us-gov\" for GovCloud (both civilian and DoD shards)."
  nullable    = false
  validation {
    condition     = contains(["aws", "aws-us-gov"], var.aws_partition)
    error_message = "aws_partition must be \"aws\" or \"aws-us-gov\"."
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

variable "resource_prefix" {
  type        = string
  description = "Prefix applied to all AWS and Databricks resource names created by this module (S3 bucket, IAM role, credentials, storage configuration, log delivery config). Must be 1-32 characters, alphanumeric, hyphens, or underscores."
  nullable    = false
  validation {
    # Conservative bound: keeps composed names (e.g. "<prefix>-audit-log-delivery-role") within AWS limits.
    condition     = length(var.resource_prefix) >= 1 && length(var.resource_prefix) <= 32 && can(regex("^[A-Za-z0-9_-]+$", var.resource_prefix))
    error_message = "resource_prefix must be 1-32 characters and contain only alphanumeric characters, hyphens, or underscores."
  }
}

variable "log_types" {
  type        = list(string)
  description = "Log types to configure delivery for. Valid values: \"AUDIT_LOGS\" (workspace audit events), \"BILLABLE_USAGE\" (DBU consumption). Defaults to both. Each value creates one databricks_mws_log_delivery configuration."
  nullable    = false
  default     = ["AUDIT_LOGS", "BILLABLE_USAGE"]
  validation {
    condition     = length(var.log_types) >= 1 && alltrue([for t in var.log_types : contains(["AUDIT_LOGS", "BILLABLE_USAGE"], t)])
    error_message = "log_types must be a non-empty list containing only \"AUDIT_LOGS\" and/or \"BILLABLE_USAGE\"."
  }
}

variable "log_retention_days" {
  type        = number
  description = "Number of days after which log objects in the S3 bucket are expired. Must be at least 1. Defaults to 365 days."
  default     = 365
  nullable    = false
  validation {
    condition     = var.log_retention_days >= 1
    error_message = "log_retention_days must be at least 1."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all AWS resources created by this module (S3 bucket, IAM role)."
  default     = {}
}

variable "force_destroy" {
  type        = bool
  description = "Allow the bucket to be destroyed even if it contains objects. Set to true for non-production environments."
  default     = false
}

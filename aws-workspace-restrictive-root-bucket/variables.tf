variable "bucket_name" {
  type        = string
  description = "Name of the Databricks workspace root storage bucket."
  nullable    = false
  validation {
    # AWS S3 bucket name constraints:
    # https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63 && can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.bucket_name)) && !can(regex("\\.\\.|-\\.", var.bucket_name))
    error_message = "bucket_name must be 3-63 characters, start and end with lowercase letter or number, contain only lowercase letters, numbers, hyphens, and periods, and not contain consecutive periods or period-hyphen combinations."
  }
}

variable "workspace_id" {
  type        = string
  description = "Databricks workspace ID. Used to scope write access to workspace-specific ephemeral paths."
  nullable    = false
  validation {
    # Databricks workspace ID format: 10-digit numeric string.
    condition     = can(regex("^[0-9]{10}$", var.workspace_id))
    error_message = "workspace_id must be a 10-digit numeric string."
  }
}

variable "region" {
  type        = string
  description = "AWS region where the workspace is deployed. Used to construct the ephemeral path prefix."
  nullable    = false
  validation {
    # AWS region naming pattern per https://docs.aws.amazon.com/general/latest/gr/rande.html
    # Covers: us-east-1, us-gov-west-1, us-iso-east-1, us-isob-east-1, etc.
    condition     = can(regex("^[a-z]{2}(-[a-z]+)?-[a-z]+-[0-9]$", var.region))
    error_message = "region must be a valid AWS region identifier (e.g., us-east-1, us-gov-west-1)."
  }
}

variable "databricks_account_id" {
  type        = string
  description = "Databricks account ID. Used in the principal tag condition to restrict access to roles tagged with this account ID."
  nullable    = false
  validation {
    # Databricks account ID format: UUID
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.databricks_account_id))
    error_message = "databricks_account_id must be a valid UUID."
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

variable "aws_partition" {
  type        = string
  description = "AWS partition for ARN construction. Use \"aws\" for commercial; \"aws-us-gov\" for GovCloud (both civilian and DoD shards)."
  nullable    = false
  validation {
    condition     = contains(["aws", "aws-us-gov"], var.aws_partition)
    error_message = "aws_partition must be \"aws\" or \"aws-us-gov\"."
  }
}

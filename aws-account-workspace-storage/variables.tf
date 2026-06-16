variable "databricks_account_id" {
  type        = string
  description = "Databricks account ID. Used when registering the S3 bucket as a storage configuration."
  nullable    = false
}

variable "aws_partition" {
  type        = string
  description = "AWS partition for ARN and bucket policy construction. Use \"aws\" for commercial; \"aws-us-gov\" for GovCloud (both civilian and DoD shards)."
  nullable    = false
  validation {
    condition     = contains(["aws", "aws-us-gov"], var.aws_partition)
    error_message = "aws_partition must be \"aws\" or \"aws-us-gov\"."
  }
}

variable "databricks_gov_shard" {
  type        = string
  description = "Databricks GovCloud shard. null for commercial; \"civilian\" for AWS GovCloud civilian (FedRAMP High); \"dod\" for IL5/DoD. GovCloud workspaces require KMS encryption on the root bucket."
  default     = null
  validation {
    condition     = var.databricks_gov_shard == null || contains(["civilian", "dod"], var.databricks_gov_shard)
    error_message = "databricks_gov_shard must be null, \"civilian\", or \"dod\"."
  }
}

variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket to create. Must be globally unique. Follows S3 naming rules: 3-63 lowercase characters, numbers, or hyphens; must start and end with a letter or number."
  nullable    = false
  validation {
    # S3 bucket naming rules per https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63 && can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name must be 3-63 characters, use only lowercase letters, numbers, and hyphens, and must start and end with a letter or number."
  }
}

variable "storage_configuration_name" {
  type        = string
  description = "Name for the databricks_mws_storage_configurations registration. Should be descriptive and unique within the Databricks account."
  nullable    = false
  validation {
    # No public Databricks-documented constraint; using conservative common-sense bounds.
    # 1-100 chars, alphanumeric + hyphen + underscore. Tighten if Databricks publishes constraints.
    condition     = length(var.storage_configuration_name) >= 1 && length(var.storage_configuration_name) <= 100 && can(regex("^[A-Za-z0-9_-]+$", var.storage_configuration_name))
    error_message = "storage_configuration_name must be 1-100 characters and contain only alphanumeric, underscore, or hyphen."
  }
}

variable "kms_key_arn" {
  type        = string
  description = "ARN of the KMS key used for server-side encryption (SSE-KMS). Required for GovCloud workspaces. Omit (null) for commercial deployments that use SSE-S3 instead."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the S3 bucket."
  default     = {}
}

variable "force_destroy" {
  type        = bool
  description = "Allow the bucket to be destroyed even if it contains objects. Set to true for non-production environments."
  default     = false
}

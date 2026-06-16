variable "credential_name" {
  type        = string
  description = "Name of the Databricks UC storage credential. Must be unique within the metastore."
  nullable    = false
  validation {
    # Conservative bounds; Databricks has not published a strict character constraint.
    # 1-100 chars, alphanumeric + hyphen + underscore.
    condition     = length(var.credential_name) >= 1 && length(var.credential_name) <= 100 && can(regex("^[A-Za-z0-9_-]+$", var.credential_name))
    error_message = "credential_name must be 1-100 characters and contain only alphanumeric, underscore, or hyphen."
  }
}

variable "role_name" {
  type        = string
  description = "Name of the AWS IAM role created for Unity Catalog storage access. Must be unique within the AWS account."
  nullable    = false
  validation {
    # AWS IAM role name constraint: 1-64 chars, [\w+=,.@-]+ per
    # https://docs.aws.amazon.com/IAM/latest/APIReference/API_CreateRole.html
    condition     = length(var.role_name) >= 1 && length(var.role_name) <= 64 && can(regex("^[\\w+=,.@-]+$", var.role_name))
    error_message = "role_name must be 1-64 characters and match the AWS IAM role name pattern [\\w+=,.@-]+ (alphanumeric, underscore, plus, equals, comma, period, at-sign, hyphen)."
  }
}

variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket that this storage credential grants access to. Used to generate the scoped S3 IAM policy via databricks_aws_unity_catalog_policy."
  nullable    = false
  validation {
    # S3 bucket name rules: 3-63 chars, lowercase alphanumeric and hyphens, no consecutive hyphens,
    # cannot start or end with a hyphen. Ref: https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63 && can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name must be 3-63 characters, start and end with a lowercase letter or digit, and contain only lowercase letters, digits, hyphens, and dots."
  }
}

variable "aws_account_id" {
  type        = string
  description = "AWS account ID where the IAM role is created. Used to construct the role ARN for the storage credential and to scope the trust policy."
  nullable    = false
  validation {
    # AWS account IDs are exactly 12 digits.
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "aws_account_id must be exactly 12 digits."
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

variable "databricks_gov_shard" {
  type        = string
  description = "Databricks GovCloud shard. null for commercial; \"civilian\" for AWS GovCloud civilian (FedRAMP High); \"dod\" for IL5/DoD. Drives the Unity Catalog IAM ARN used in the trust policy."
  default     = null
  validation {
    condition     = var.databricks_gov_shard == null || contains(["civilian", "dod"], var.databricks_gov_shard)
    error_message = "databricks_gov_shard must be null, \"civilian\", or \"dod\"."
  }
}

variable "kms_key_arn" {
  type        = string
  description = "Optional ARN of a KMS key used to encrypt the S3 bucket. When provided, the generated IAM policy includes kms:GenerateDataKey* and kms:Decrypt permissions. Omit (null) if the bucket uses SSE-S3 or no encryption."
  default     = null
}

variable "comment" {
  type        = string
  description = "Optional human-readable description for the Databricks storage credential."
  default     = null
}

variable "isolation_mode" {
  type        = string
  description = "Isolation mode for the storage credential. Use ISOLATION_MODE_ISOLATED for regulated environments."
  default     = null
  validation {
    condition     = var.isolation_mode == null || contains(["ISOLATION_MODE_ISOLATED", "ISOLATION_MODE_OPEN"], var.isolation_mode)
    error_message = "isolation_mode must be null, \"ISOLATION_MODE_ISOLATED\", or \"ISOLATION_MODE_OPEN\"."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the AWS IAM role."
  default     = {}
}

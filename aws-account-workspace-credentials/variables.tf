variable "databricks_account_id" {
  type        = string
  description = "Databricks account ID. Used as the external ID in the AWS IAM role's assume-role policy."
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

variable "role_name" {
  type        = string
  description = "Name of the AWS IAM cross-account role. Must be unique within the AWS account."
  nullable    = false
  validation {
    # AWS IAM role name constraint: 1-64 chars, [\w+=,.@-]+ per
    # https://docs.aws.amazon.com/IAM/latest/APIReference/API_CreateRole.html
    condition     = length(var.role_name) >= 1 && length(var.role_name) <= 64 && can(regex("^[\\w+=,.@-]+$", var.role_name))
    error_message = "role_name must be 1-64 characters and match the AWS IAM role name pattern [\\w+=,.@-]+ (alphanumeric, underscore, plus, equals, comma, period, at-sign, hyphen)."
  }
}

variable "credentials_name" {
  type        = string
  description = "Name for the databricks_mws_credentials registration. Should be descriptive and unique within the Databricks account."
  nullable    = false
  validation {
    # No public Databricks-documented constraint; using conservative common-sense bounds.
    # 1-100 chars, alphanumeric + hyphen + underscore. Tighten if Databricks publishes constraints.
    condition     = length(var.credentials_name) >= 1 && length(var.credentials_name) <= 100 && can(regex("^[A-Za-z0-9_-]+$", var.credentials_name))
    error_message = "credentials_name must be 1-100 characters and contain only alphanumeric, underscore, or hyphen."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the AWS IAM role."
  default     = {}
}

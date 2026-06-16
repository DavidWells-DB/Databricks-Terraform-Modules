variable "databricks_account_id" {
  type        = string
  description = "Databricks account ID. Used as the account_id field on both databricks_mws_customer_managed_keys resources."
  nullable    = false
}

variable "aws_account_id" {
  type        = string
  description = "AWS account ID of the customer account. Used in KMS key policies to grant the account root full key administration."
  nullable    = false
  validation {
    # AWS account IDs are exactly 12 decimal digits.
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "aws_account_id must be exactly 12 decimal digits."
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
  description = "Databricks GovCloud shard. null for commercial; \"civilian\" for AWS GovCloud civilian (FedRAMP High); \"dod\" for IL5/DoD."
  default     = null
  validation {
    condition     = var.databricks_gov_shard == null || contains(["civilian", "dod"], var.databricks_gov_shard)
    error_message = "databricks_gov_shard must be null, \"civilian\", or \"dod\"."
  }
}

variable "cross_account_role_arn" {
  type        = string
  description = "ARN of the Databricks cross-account IAM role. Added to the storage key policy so EBS volumes on workspace clusters can use the key."
  nullable    = false
  validation {
    # Must look like an IAM role ARN in aws or aws-us-gov partition.
    condition     = can(regex("^arn:(aws|aws-us-gov):iam::[0-9]{12}:role/.+$", var.cross_account_role_arn))
    error_message = "cross_account_role_arn must be a valid IAM role ARN (arn:aws:iam::<account>:role/<name> or arn:aws-us-gov:...)."
  }
}

variable "managed_services_key_alias" {
  type        = string
  description = "AWS KMS alias for the managed-services CMK (notebooks, secrets, SQL history). Must start with \"alias/\"."
  nullable    = false
  validation {
    condition     = can(regex("^alias/.+$", var.managed_services_key_alias))
    error_message = "managed_services_key_alias must start with \"alias/\"."
  }
}

variable "workspace_storage_key_alias" {
  type        = string
  description = "AWS KMS alias for the workspace-storage CMK (DBFS root bucket, cluster EBS volumes). Must start with \"alias/\"."
  nullable    = false
  validation {
    condition     = can(regex("^alias/.+$", var.workspace_storage_key_alias))
    error_message = "workspace_storage_key_alias must start with \"alias/\"."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to both AWS KMS keys."
  default     = {}
}

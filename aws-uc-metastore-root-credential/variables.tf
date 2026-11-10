variable "metastore_id" {
  type        = string
  description = "The metastore the root-storage credential belongs to (databricks_metastore.id — NOT a workspace-scoped metastore). The data access registers HERE, on the account plane, by construction."
  nullable    = false
  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.metastore_id))
    error_message = "metastore_id must be a lowercase UUID."
  }
}

variable "credential_name" {
  type        = string
  description = "Name for the metastore data access (the root-storage credential)."
  nullable    = false
}

variable "role_name" {
  type        = string
  description = "IAM role name for the credential (the module creates this role; its ARN is pre-computed from account + name so the credential can exist first)."
  nullable    = false
}

variable "bucket_name" {
  type        = string
  description = "S3 bucket for the metastore's root storage."
  nullable    = false
}

variable "aws_account_id" {
  type        = string
  description = "AWS account ID (12 digits) — used to pre-compute the role ARN."
  nullable    = false
  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "aws_account_id must be exactly 12 digits."
  }
}

variable "aws_partition" {
  type        = string
  description = "AWS partition: \"aws\" (commercial) or \"aws-us-gov\" (GovCloud)."
  default     = "aws"
  nullable    = false
  validation {
    condition     = contains(["aws", "aws-us-gov"], var.aws_partition)
    error_message = "aws_partition must be \"aws\" or \"aws-us-gov\"."
  }
}

variable "skip_validation" {
  type        = bool
  description = "Skip the credential validation at creation (the IAM role does not exist yet — the trust is built FROM the credential's external_id afterwards; validated on subsequent applies)."
  default     = true
  nullable    = false
}

variable "comment" {
  type        = string
  description = "Comment for the data access."
  default     = "Metastore root storage credential (managed by aws-uc-metastore-root-credential)"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the IAM role."
  default     = {}
}

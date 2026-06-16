terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = ">= 1.50"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "databricks" {
  alias         = "account"
  host          = var.databricks_account_host
  account_id    = var.databricks_account_id
  client_id     = var.databricks_client_id
  client_secret = var.databricks_client_secret
}

data "aws_caller_identity" "current" {}

module "encryption_keys" {
  source = "../.."

  providers = {
    databricks.account = databricks.account
  }

  databricks_account_id       = var.databricks_account_id
  aws_account_id              = data.aws_caller_identity.current.account_id
  aws_partition               = "aws"
  databricks_gov_shard        = null
  cross_account_role_arn      = var.cross_account_role_arn
  managed_services_key_alias  = "alias/databricks-managed-services-example"
  workspace_storage_key_alias = "alias/databricks-workspace-storage-example"

  tags = {
    Module  = "aws-account-encryption-keys"
    Example = "basic"
  }
}

variable "aws_region" {
  type        = string
  description = "AWS region for the provider."
  default     = "us-east-1"
}

variable "databricks_account_host" {
  type        = string
  description = "Databricks account host. Commercial: https://accounts.cloud.databricks.com. GovCloud civilian: https://accounts.cloud.databricks.us. DoD: https://accounts-dod.cloud.databricks.mil."
  default     = "https://accounts.cloud.databricks.com"
}

variable "databricks_account_id" {
  type        = string
  description = "Databricks account ID."
}

variable "databricks_client_id" {
  type        = string
  description = "Databricks account-level service principal application ID (OAuth M2M)."
}

variable "databricks_client_secret" {
  type        = string
  description = "Databricks account-level service principal secret (OAuth M2M)."
  sensitive   = true
}

variable "cross_account_role_arn" {
  type        = string
  description = "ARN of the Databricks cross-account IAM role. Created by the aws-account-workspace-credentials module."
}

output "managed_services_key_id" {
  description = "Databricks CMK object ID for managed services."
  value       = module.encryption_keys.managed_services_key_id
}

output "workspace_storage_key_id" {
  description = "Databricks CMK object ID for workspace storage."
  value       = module.encryption_keys.workspace_storage_key_id
}

output "managed_services_key_arn" {
  description = "ARN of the managed-services KMS key."
  value       = module.encryption_keys.managed_services_key_arn
}

output "workspace_storage_key_arn" {
  description = "ARN of the workspace-storage KMS key."
  value       = module.encryption_keys.workspace_storage_key_arn
}

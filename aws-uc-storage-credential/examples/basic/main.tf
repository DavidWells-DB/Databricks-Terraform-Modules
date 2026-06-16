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
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "databricks" {
  alias         = "workspace"
  host          = var.databricks_workspace_url
  client_id     = var.databricks_client_id
  client_secret = var.databricks_client_secret
}

module "uc_storage_credential" {
  source = "../.."

  providers = {
    databricks.workspace = databricks.workspace
  }

  credential_name      = "example-uc-storage-cred"
  role_name            = "databricks-uc-storage-example"
  bucket_name          = var.s3_bucket_name
  aws_account_id       = var.aws_account_id
  aws_partition        = "aws"
  databricks_gov_shard = null

  comment        = "Managed by Terraform — aws-uc-storage-credential example"
  isolation_mode = "ISOLATION_MODE_OPEN"

  tags = {
    Module  = "aws-uc-storage-credential"
    Example = "basic"
  }
}

variable "aws_region" {
  type        = string
  description = "AWS region for the provider."
  default     = "us-east-1"
}

variable "aws_account_id" {
  type        = string
  description = "12-digit AWS account ID where the IAM role is created."
}

variable "s3_bucket_name" {
  type        = string
  description = "Name of the existing S3 bucket that this storage credential grants Unity Catalog access to."
}

variable "databricks_workspace_url" {
  type        = string
  description = "Databricks workspace URL (e.g. https://my-workspace.cloud.databricks.com)."
}

variable "databricks_client_id" {
  type        = string
  description = "Databricks workspace-level service principal application ID (OAuth M2M)."
}

variable "databricks_client_secret" {
  type        = string
  description = "Databricks workspace-level service principal secret (OAuth M2M)."
  sensitive   = true
}

output "storage_credential_id" {
  description = "Unique ID of the created UC storage credential."
  value       = module.uc_storage_credential.storage_credential_id
}

output "iam_role_arn" {
  description = "ARN of the AWS IAM role created for Unity Catalog storage access."
  value       = module.uc_storage_credential.iam_role_arn
}

output "external_id" {
  description = "Databricks-generated external ID embedded in the IAM role trust policy."
  value       = module.uc_storage_credential.external_id
}

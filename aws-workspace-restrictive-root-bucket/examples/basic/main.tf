terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "restrictive_root_bucket" {
  source = "../.."

  bucket_name           = var.bucket_name
  workspace_id          = var.workspace_id
  region                = var.aws_region
  databricks_account_id = var.databricks_account_id
  aws_partition         = "aws"
  databricks_gov_shard  = null
}

variable "aws_region" {
  type        = string
  description = "AWS region where the workspace is deployed."
  default     = "us-east-1"
}

variable "bucket_name" {
  type        = string
  description = "Name of the Databricks workspace root storage bucket."
}

variable "workspace_id" {
  type        = string
  description = "Databricks workspace ID (10-digit numeric string)."
}

variable "databricks_account_id" {
  type        = string
  description = "Databricks account ID (UUID)."
}

output "bucket_policy_id" {
  value = module.restrictive_root_bucket.bucket_policy_id
}

output "bucket_name" {
  value = module.restrictive_root_bucket.bucket_name
}

output "databricks_aws_account_id" {
  value = module.restrictive_root_bucket.databricks_aws_account_id
}

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

module "workspace_storage" {
  source = "../.."

  providers = {
    databricks.account = databricks.account
  }

  databricks_account_id      = var.databricks_account_id
  aws_partition              = "aws"
  databricks_gov_shard       = null
  bucket_name                = var.bucket_name
  storage_configuration_name = "example-storage"

  tags = {
    Module  = "aws-account-workspace-storage"
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

variable "bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name for workspace root storage."
}

output "storage_configuration_id" {
  value = module.workspace_storage.storage_configuration_id
}

output "bucket_name" {
  value = module.workspace_storage.bucket_name
}

output "bucket_arn" {
  value = module.workspace_storage.bucket_arn
}

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
  alias         = "account"
  host          = var.databricks_account_host
  account_id    = var.databricks_account_id
  client_id     = var.databricks_client_id
  client_secret = var.databricks_client_secret
}

module "log_delivery" {
  source = "../.."

  providers = {
    databricks.account = databricks.account
  }

  databricks_account_id = var.databricks_account_id
  aws_partition         = "aws"
  databricks_gov_shard  = null
  resource_prefix       = "myorg-example"

  # Deliver both audit events and billable usage to S3 (default).
  log_types = ["AUDIT_LOGS", "BILLABLE_USAGE"]

  tags = {
    Module  = "aws-account-log-delivery"
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

output "bucket_name" {
  description = "S3 bucket receiving Databricks log files."
  value       = module.log_delivery.bucket_name
}

output "role_arn" {
  description = "IAM role ARN used by Databricks for log delivery."
  value       = module.log_delivery.role_arn
}

output "log_delivery_configuration_ids" {
  description = "Map of log type to Databricks log delivery configuration ID."
  value       = module.log_delivery.log_delivery_configuration_ids
}

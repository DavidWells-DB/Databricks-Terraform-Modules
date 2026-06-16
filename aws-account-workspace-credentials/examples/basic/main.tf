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

module "workspace_credentials" {
  source = "../.."

  providers = {
    databricks.account = databricks.account
  }

  databricks_account_id = var.databricks_account_id
  aws_partition         = "aws"
  databricks_gov_shard  = null
  role_name             = "databricks-cross-account-example"
  credentials_name      = "example-creds"

  tags = {
    Module  = "aws-account-workspace-credentials"
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

output "credentials_id" {
  value = module.workspace_credentials.credentials_id
}

output "role_arn" {
  value = module.workspace_credentials.role_arn
}

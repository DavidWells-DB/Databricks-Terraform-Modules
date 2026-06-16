terraform {
  required_version = ">= 1.7.0"
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = ">= 1.50"
    }
  }
}

provider "databricks" {
  alias         = "account"
  host          = var.databricks_account_host
  account_id    = var.databricks_account_id
  client_id     = var.databricks_client_id
  client_secret = var.databricks_client_secret
}

module "metastore" {
  source = "../.."

  providers = {
    databricks.account = databricks.account
  }

  metastore_name   = "example-metastore"
  region           = var.region
  storage_root_url = var.storage_root_url
  data_access_name = "example-data-access"

  storage_credential = {
    aws_iam_role = {
      role_arn = var.iam_role_arn
    }
  }

  owner_group = var.owner_group
}

variable "region" {
  type        = string
  description = "AWS region for the metastore (e.g., \"us-east-1\")."
  default     = "us-east-1"
}

variable "storage_root_url" {
  type        = string
  description = "S3 URL for the metastore root (e.g., \"s3://my-uc-bucket/metastore\")."
}

variable "iam_role_arn" {
  type        = string
  description = "ARN of the AWS IAM role to use as the metastore default data access credential."
}

variable "owner_group" {
  type        = string
  description = "Databricks account group to set as the metastore owner. Optional."
  default     = null
}

variable "databricks_account_host" {
  type        = string
  description = "Databricks account host. Commercial AWS: https://accounts.cloud.databricks.com."
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

output "metastore_id" {
  value = module.metastore.metastore_id
}

output "metastore_name" {
  value = module.metastore.metastore_name
}

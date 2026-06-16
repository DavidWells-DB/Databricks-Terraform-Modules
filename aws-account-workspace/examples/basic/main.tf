terraform {
  required_version = ">= 1.7.0"
  required_providers {
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

provider "databricks" {
  alias         = "account"
  host          = var.databricks_account_host
  account_id    = var.databricks_account_id
  client_id     = var.databricks_client_id
  client_secret = var.databricks_client_secret
}

module "workspace" {
  source = "../.."

  providers = {
    databricks.account = databricks.account
  }

  databricks_account_id    = var.databricks_account_id
  workspace_name           = "example-workspace"
  region                   = var.aws_region
  databricks_gov_shard     = null
  credentials_id           = var.credentials_id
  storage_configuration_id = var.storage_configuration_id
  databricks_network_id    = var.databricks_network_id

  custom_tags = {
    Module  = "aws-account-workspace"
    Example = "basic"
  }
}

variable "aws_region" {
  type        = string
  description = "AWS region where the workspace is deployed."
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

variable "credentials_id" {
  type        = string
  description = "Databricks credentials object ID (from aws-account-workspace-credentials module)."
}

variable "storage_configuration_id" {
  type        = string
  description = "Databricks storage configuration ID (from aws-account-workspace-storage module)."
}

variable "databricks_network_id" {
  type        = string
  description = "Databricks network configuration ID (from aws-account-network or aws-account-network-vpc module)."
}

output "workspace_id" {
  value = module.workspace.workspace_id
}

output "workspace_url" {
  value = module.workspace.workspace_url
}

output "deployment_name" {
  value = module.workspace.deployment_name
}

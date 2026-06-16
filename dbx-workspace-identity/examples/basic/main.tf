terraform {
  required_version = ">= 1.7.0"
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = ">= 1.14"
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

module "workspace_identity" {
  source = "../.."

  providers = {
    databricks.account = databricks.account
  }

  workspace_id = var.workspace_id

  assignments = {
    data_engineering = {
      principal_id = var.data_engineering_group_id
      roles        = ["USER"]
    }
    workspace_admins = {
      principal_id = var.admin_group_id
      roles        = ["ADMIN"]
    }
  }
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

variable "workspace_id" {
  type        = number
  description = "Databricks workspace ID to assign principals to."
}

variable "data_engineering_group_id" {
  type        = number
  description = "Databricks account-level principal ID for the data engineering group."
}

variable "admin_group_id" {
  type        = number
  description = "Databricks account-level principal ID for the workspace admin group."
}

output "assignment_ids" {
  description = "Map of assignment label to Databricks permission assignment ID."
  value       = module.workspace_identity.assignment_ids
}

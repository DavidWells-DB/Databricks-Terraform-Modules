terraform {
  required_version = ">= 1.7.0"
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = ">= 1.39"
    }
  }
}

provider "databricks" {
  alias         = "workspace"
  host          = var.databricks_workspace_host
  client_id     = var.databricks_client_id
  client_secret = var.databricks_client_secret
}

module "uc_catalogs" {
  source = "../.."

  providers = {
    databricks.workspace = databricks.workspace
  }

  metastore_id = var.metastore_id

  catalogs = {
    analytics = {
      comment        = "Analytics catalog for BI and reporting workloads"
      isolation_mode = "OPEN"
      properties = {
        team  = "analytics"
        owner = "data-engineering"
      }
      grants = [
        {
          principal  = "analysts"
          privileges = ["USE_CATALOG", "USE_SCHEMA", "SELECT"]
        },
        {
          principal  = "data-engineers"
          privileges = ["USE_CATALOG", "CREATE_SCHEMA", "CREATE_TABLE"]
        }
      ]
    }
    sandbox = {
      comment        = "Sandbox catalog for exploratory development"
      isolation_mode = "OPEN"
      properties     = {}
      grants         = []
    }
  }
}

variable "databricks_workspace_host" {
  type        = string
  description = "Databricks workspace URL (e.g. https://<workspace-id>.azuredatabricks.net or https://<workspace-id>.cloud.databricks.com)."
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

variable "metastore_id" {
  type        = string
  description = "Unity Catalog metastore ID."
}

output "catalog_ids" {
  description = "Map of catalog name to catalog ID."
  value       = module.uc_catalogs.catalog_ids
}

output "catalog_names" {
  description = "Set of catalog names created."
  value       = module.uc_catalogs.catalog_names
}

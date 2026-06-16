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

module "uc_schemas" {
  source = "../.."

  providers = {
    databricks.workspace = databricks.workspace
  }

  catalog_name = var.catalog_name

  schemas = {
    raw = {
      comment = "Raw ingestion schema for landing zone data"
      properties = {
        team  = "data-engineering"
        layer = "raw"
      }
      grants = [
        {
          principal  = "data-engineers"
          privileges = ["USE_SCHEMA", "CREATE_TABLE", "CREATE_VOLUME"]
        }
      ]
    }
    curated = {
      comment    = "Curated schema for cleaned and validated datasets"
      properties = {}
      grants     = []
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

variable "catalog_name" {
  type        = string
  description = "Name of the existing Unity Catalog catalog in which schemas are created."
}

output "schema_ids" {
  description = "Map of schema name to schema ID."
  value       = module.uc_schemas.schema_ids
}

output "schema_names" {
  description = "Set of schema names created."
  value       = module.uc_schemas.schema_names
}

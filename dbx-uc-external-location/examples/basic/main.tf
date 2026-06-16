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
  alias         = "workspace"
  host          = var.databricks_workspace_url
  client_id     = var.databricks_client_id
  client_secret = var.databricks_client_secret
}

module "external_locations" {
  source = "../.."

  providers = {
    databricks.workspace = databricks.workspace
  }

  locations = {
    raw_data = {
      url                   = "s3://my-databricks-bucket/raw"
      storage_credential_id = var.aws_storage_credential_id
      comment               = "Raw ingestion landing zone"
      grants = {
        "data-engineers" = ["READ_FILES", "WRITE_FILES"]
      }
    }

    curated_data = {
      url                   = "s3://my-databricks-bucket/curated"
      storage_credential_id = var.aws_storage_credential_id
      comment               = "Curated / processed data zone"
      read_only             = false
      grants = {
        "data-engineers" = ["READ_FILES", "WRITE_FILES"]
        "data-analysts"  = ["READ_FILES"]
      }
    }
  }
}

variable "databricks_workspace_url" {
  type        = string
  description = "Databricks workspace URL (e.g. https://adb-1234567890.1.azuredatabricks.net or https://my-workspace.cloud.databricks.com)."
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

variable "aws_storage_credential_id" {
  type        = string
  description = "ID of an existing databricks_storage_credential that grants access to the S3 locations."
}

output "external_location_ids" {
  value = module.external_locations.external_location_ids
}

output "external_location_urls" {
  value = module.external_locations.external_location_urls
}

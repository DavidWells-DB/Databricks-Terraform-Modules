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
  alias = "workspace"
  host  = var.databricks_workspace_host
  token = var.databricks_workspace_token
}

module "sql_warehouse" {
  source = "../.."

  providers = {
    databricks.workspace = databricks.workspace
  }

  name                      = "example-warehouse"
  cluster_size              = "Small"
  warehouse_type            = "PRO"
  auto_stop_mins            = 10
  min_num_clusters          = 1
  max_num_clusters          = 2
  spot_instance_policy      = "COST_OPTIMIZED"
  channel                   = "CURRENT"
  enable_photon             = true
  enable_serverless_compute = false

  permissions = {
    "users" = "CAN_USE"
  }

  tags = {
    Module  = "dbx-workspace-sql-warehouse"
    Example = "basic"
  }
}

variable "databricks_workspace_host" {
  type        = string
  description = "Databricks workspace URL (e.g., https://dbc-12345678-abcd.cloud.databricks.com)."
}

variable "databricks_workspace_token" {
  type        = string
  description = "Databricks personal access token or service principal token for workspace API authentication."
  sensitive   = true
}

output "warehouse_id" {
  value = module.sql_warehouse.warehouse_id
}

output "jdbc_url" {
  value = module.sql_warehouse.jdbc_url
}

output "data_source_id" {
  value = module.sql_warehouse.data_source_id
}

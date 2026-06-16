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
  alias      = "account"
  host       = var.databricks_account_host
  account_id = var.databricks_account_id

  client_id     = var.databricks_client_id
  client_secret = var.databricks_client_secret
}

# The workspace provider is required by the module's configuration_aliases declaration.
# In this basic example, default_catalog_name is null so no workspace-level resource is created.
# Point this at any workspace in the account; it will not be used.
provider "databricks" {
  alias = "workspace"
  host  = var.databricks_workspace_url

  client_id     = var.databricks_client_id
  client_secret = var.databricks_client_secret
}

module "metastore_assignment" {
  source = "../.."

  providers = {
    databricks.account   = databricks.account
    databricks.workspace = databricks.workspace
  }

  metastore_id = var.metastore_id

  workspace_ids = {
    prod = var.prod_workspace_id
    dev  = var.dev_workspace_id
  }

  # default_catalog_name = null (default) — no default catalog is set.
  # To set a default catalog, set this to the catalog name and configure
  # databricks.workspace against the target workspace URL.
}

variable "databricks_account_host" {
  type        = string
  description = "Databricks account host. Commercial: https://accounts.cloud.databricks.com."
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

variable "databricks_workspace_url" {
  type        = string
  description = "URL of a workspace in the account. Required by the databricks.workspace provider alias even when default_catalog_name is null."
}

variable "metastore_id" {
  type        = string
  description = "ID of the Unity Catalog metastore to assign (UUID format)."
}

variable "prod_workspace_id" {
  type        = string
  description = "Numeric ID of the production workspace."
}

variable "dev_workspace_id" {
  type        = string
  description = "Numeric ID of the development workspace."
}

output "assignment_ids" {
  description = "Metastore assignment IDs keyed by workspace label."
  value       = module.metastore_assignment.assignment_ids
}

output "assigned_workspace_ids" {
  description = "Workspace IDs that were assigned the metastore."
  value       = module.metastore_assignment.assigned_workspace_ids
}

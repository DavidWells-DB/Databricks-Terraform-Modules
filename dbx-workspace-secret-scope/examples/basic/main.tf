terraform {
  required_version = ">= 1.7.0"
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = ">= 1.14"
    }
  }
}

provider "databricks" {
  alias         = "workspace"
  host          = var.databricks_workspace_url
  client_id     = var.databricks_client_id
  client_secret = var.databricks_client_secret
}

module "secret_scopes" {
  source = "../.."

  providers = {
    databricks.workspace = databricks.workspace
  }

  scopes = {
    "app-secrets" = {
      initial_manage_principal = "users"
    }
    "infra-secrets" = {}
  }
}

variable "databricks_workspace_url" {
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

output "scope_names" {
  value = module.secret_scopes.scope_names
}

output "scope_backend_types" {
  value = module.secret_scopes.scope_backend_types
}

terraform {
  required_version = ">= 1.7.0"
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = ">= 1.73"
    }
  }
}

provider "databricks" {
  host          = var.databricks_workspace_host
  client_id     = var.databricks_client_id
  client_secret = var.databricks_client_secret
}

module "workspace_compliance_settings" {
  source = "../.."

  compliance_security_profile_enabled = true
  compliance_standards                = ["HIPAA"]

  enhanced_security_monitoring_enabled = true
  automatic_cluster_update_enabled     = true

  automatic_cluster_update_maintenance_window = {
    week_day_based_schedule = {
      day_of_week = "SUNDAY"
      frequency   = "EVERY_WEEK"
      window_start_time = {
        hours   = 2
        minutes = 0
      }
    }
  }

  disable_legacy_access = true
  disable_legacy_dbfs   = true
}

variable "databricks_workspace_host" {
  type        = string
  description = "Databricks workspace URL (e.g. https://adb-<id>.<region>.azuredatabricks.net or https://<id>.cloud.databricks.com)."
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

output "compliance_security_profile_enabled" {
  value = module.workspace_compliance_settings.compliance_security_profile_enabled
}

output "compliance_standards" {
  value = module.workspace_compliance_settings.compliance_standards
}

output "legacy_access_disabled" {
  value = module.workspace_compliance_settings.legacy_access_disabled
}

output "legacy_dbfs_disabled" {
  value = module.workspace_compliance_settings.legacy_dbfs_disabled
}

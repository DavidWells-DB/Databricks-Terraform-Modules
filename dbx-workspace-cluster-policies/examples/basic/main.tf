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
  host          = var.workspace_url
  client_id     = var.databricks_client_id
  client_secret = var.databricks_client_secret
}

module "cluster_policies" {
  source = "../.."

  providers = {
    databricks.workspace = databricks.workspace
  }

  policies = {
    # Custom definition — full control via Policy Definition Language JSON
    "cost-controlled" = {
      description = "Limits DBU consumption and enforces autotermination."
      definition = jsonencode({
        "dbus_per_hour" = {
          type     = "range"
          maxValue = 10
        }
        "autotermination_minutes" = {
          type   = "fixed"
          value  = 20
          hidden = true
        }
      })
    }

    # Policy family inheritance — extend a Databricks-managed baseline
    "personal-compute" = {
      description      = "Personal compute via policy family with shortened autotermination."
      policy_family_id = "personal-vm"
      policy_family_definition_overrides = jsonencode({
        "autotermination_minutes" = {
          type   = "fixed"
          value  = 120
          hidden = true
        }
      })
    }
  }

  policy_assignments = {
    "cost-controlled" = {
      access_controls = [
        { group_name = "data-engineers" },
        { group_name = "data-scientists" },
      ]
    }
    "personal-compute" = {
      access_controls = [
        { group_name = "all-workspace-users" },
      ]
    }
  }
}

variable "workspace_url" {
  type        = string
  description = "Databricks workspace URL (e.g. https://adb-1234567890.1.azuredatabricks.net)."
}

variable "databricks_client_id" {
  type        = string
  description = "Service principal application ID for workspace authentication (OAuth M2M)."
}

variable "databricks_client_secret" {
  type        = string
  description = "Service principal secret for workspace authentication (OAuth M2M)."
  sensitive   = true
}

output "policy_ids" {
  description = "Map of policy name to Databricks cluster policy ID."
  value       = module.cluster_policies.policy_ids
}

output "policy_policy_ids" {
  description = "Map of policy name to Databricks-internal policy_id (for use in cluster definitions)."
  value       = module.cluster_policies.policy_policy_ids
}

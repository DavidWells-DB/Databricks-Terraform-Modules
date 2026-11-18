terraform {
  required_version = ">= 1.7.0"

  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = ">= 1.81"
    }
  }
}

provider "databricks" {
  alias = "workspace"
  host  = "https://adb-123456789012345.1.azuredatabricks.net"
  token = var.token
}

variable "token" { type = string }

module "bindings" {
  source = "../.."

  providers = { databricks.workspace = databricks.workspace }

  bindings = {
    "finance-to-analytics-ws" = {
      workspace_id   = 123456789012345
      securable_name = "finance"
      # securable_type defaults to "catalog"; binding_type defaults to read-write.
    }
    "finance-readonly-to-audit-ws" = {
      workspace_id   = 999999999999999
      securable_name = "finance"
      binding_type   = "BINDING_TYPE_READ_ONLY"
    }
  }
}

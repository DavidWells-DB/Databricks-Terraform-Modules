variable "metastore_id" {
  type        = string
  description = "ID of the Unity Catalog metastore to assign. Obtain from the databricks_metastore resource or a data source."
  nullable    = false
  validation {
    # Metastore IDs are UUIDs. Enforce format to catch copy-paste errors early.
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.metastore_id))
    error_message = "metastore_id must be a valid UUID (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)."
  }
}

variable "workspace_ids" {
  type        = map(string)
  description = <<-EOT
    Map of workspace assignments. Keys are human-readable labels; values are numeric Databricks
    workspace IDs. The metastore will be assigned to every workspace in this map.

    Example:
      workspace_ids = {
        prod = "123456789012345"
        dev  = "234567890123456"
      }
  EOT
  nullable    = false

  validation {
    condition     = length(var.workspace_ids) >= 1
    error_message = "workspace_ids must contain at least one entry."
  }

  validation {
    condition = alltrue([
      for k, v in var.workspace_ids : can(regex("^[0-9]+$", v))
    ])
    error_message = "Each value in workspace_ids must be a numeric string (Databricks numeric workspace ID)."
  }
}

variable "default_catalog_name" {
  type        = string
  description = <<-EOT
    Catalog to set as the default namespace for the workspace configured in the
    databricks.workspace provider alias. When set, a databricks_default_namespace_setting
    resource is created for that workspace. When null, no default catalog is configured.
    Requires the databricks.workspace provider alias to be configured against the target
    workspace URL.
  EOT
  default     = null
  nullable    = true
  validation {
    condition     = var.default_catalog_name == null || (length(trimspace(var.default_catalog_name)) >= 1 && var.default_catalog_name == trimspace(var.default_catalog_name))
    error_message = "default_catalog_name must be null or a non-empty string with no leading or trailing whitespace."
  }
}

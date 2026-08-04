variable "metastore_id" {
  type        = string
  description = "ID of the Unity Catalog metastore to assign. OPTIONAL: leave null to create no assignment at all — Databricks auto-assigns the region's DEFAULT metastore to a new workspace, so an explicit assignment is only needed to override that (e.g. multiple metastores in the region with no default). When null, pass workspace_ids = {} as well; the default_catalog_name resource still works independently."
  default     = null
  nullable    = true
  validation {
    # Metastore IDs are UUIDs. Enforce format to catch copy-paste errors early.
    condition     = var.metastore_id == null || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.metastore_id))
    error_message = "metastore_id, when set, must be a valid metastore UUID."
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

  # NOTE: an EMPTY map is now valid — it is the "rely on the region's default metastore"
  # case (metastore_id = null, no explicit assignment). The coherence validation below
  # enforces that metastore_id and workspace_ids are set together, which replaces the old
  # blanket "must contain at least one entry" rule.

  validation {
    condition = alltrue([
      for k, v in var.workspace_ids : can(regex("^[0-9]+$", v))
    ])
    error_message = "Each value in workspace_ids must be a numeric string (Databricks numeric workspace ID)."
  }
  validation {
    # Coherence: assigning requires both a metastore and at least one workspace. Passing a
    # metastore with no workspaces (or workspaces with no metastore) silently does nothing.
    condition     = (var.metastore_id == null) == (length(var.workspace_ids) == 0)
    error_message = "metastore_id and workspace_ids must be set together: supply both to create assignments, or neither (workspace_ids = {}) to rely on the region's default metastore."
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

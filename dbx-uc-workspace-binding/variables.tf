variable "bindings" {
  type = map(object({
    workspace_id   = number
    securable_name = string
    securable_type = optional(string, "catalog")
    binding_type   = optional(string, "BINDING_TYPE_READ_WRITE")
  }))
  description = <<-EOT
    Workspace bindings, keyed by a caller-chosen unique name (the key is the for_each
    constant — e.g. "<securable>-to-<workspace>"). Each entry: workspace_id (required),
    securable_name (required), securable_type (default "catalog"), binding_type
    ("BINDING_TYPE_READ_WRITE" | "BINDING_TYPE_READ_ONLY", default read-write).
    Pair with dbx-uc-catalog's isolation_mode = "ISOLATED" — that un-shares the catalog;
    these bindings re-grant exactly the intended workspaces.
  EOT
  nullable    = false
  validation {
    condition = alltrue([
      for k, v in var.bindings :
      contains(["BINDING_TYPE_READ_WRITE", "BINDING_TYPE_READ_ONLY"], v.binding_type)
    ])
    error_message = "Each binding's binding_type must be \"BINDING_TYPE_READ_WRITE\" or \"BINDING_TYPE_READ_ONLY\"."
  }
  validation {
    condition = alltrue([
      for k, v in var.bindings :
      contains(["catalog", "storage_credential", "external_location", "foreign_connection", "catalog_function"], v.securable_type)
    ])
    error_message = "Each binding's securable_type must be one of catalog, storage_credential, external_location, foreign_connection, catalog_function."
  }
}

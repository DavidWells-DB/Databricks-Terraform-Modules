variable "locations" {
  type = map(object({
    url                   = string
    storage_credential_id = string
    comment               = optional(string)
    read_only             = optional(bool, false)
    skip_validation       = optional(bool, false)
    grants                = optional(map(list(string)), {})
  }))
  description = <<-EOT
    Map of external location name to configuration. Each key becomes the external location name
    registered in Unity Catalog.

    Attributes:
      url                   - Cloud storage path (e.g. s3://bucket/prefix, abfss://container@account.dfs.core.windows.net/prefix, gs://bucket/prefix).
      storage_credential_id - ID of the databricks_storage_credential that grants access to this path.
      comment               - Optional human-readable description attached to the external location.
      read_only             - When true, the external location is registered as read-only. Defaults to false.
      skip_validation       - When true, Databricks skips credential validation during creation. Set to true in locked-down environments. Defaults to false.
      grants                - Map of principal → list of privileges. Example: { "data-eng@example.com" = ["READ_FILES", "WRITE_FILES"] }.
  EOT
  nullable    = false
  validation {
    # Every location URL must start with a supported cloud storage scheme.
    condition = alltrue([
      for name, loc in var.locations :
      can(regex("^(s3|abfss|gs)://", loc.url))
    ])
    error_message = "Every location url must begin with s3://, abfss://, or gs://."
  }
  validation {
    # Every location name must be non-empty and not contain whitespace.
    condition = alltrue([
      for name, loc in var.locations :
      length(trimspace(name)) >= 1 && name == trimspace(name) && can(regex("^[A-Za-z0-9_-]+$", name))
    ])
    error_message = "Every location name (map key) must be 1+ characters and contain only alphanumeric characters, underscores, or hyphens."
  }
  validation {
    # storage_credential_id must be non-empty for every entry.
    condition = alltrue([
      for name, loc in var.locations :
      length(trimspace(loc.storage_credential_id)) >= 1
    ])
    error_message = "storage_credential_id must be a non-empty string for every location."
  }
}

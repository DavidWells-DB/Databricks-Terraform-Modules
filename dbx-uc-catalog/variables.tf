variable "metastore_id" {
  type        = string
  description = "ID of the Unity Catalog metastore to which these catalogs belong. Required to scope catalog creation to the correct metastore."
  nullable    = false
  validation {
    # Metastore IDs are UUIDs. Validate format to catch copy-paste errors early at plan time.
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.metastore_id))
    error_message = "metastore_id must be a lowercase UUID (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)."
  }
}

variable "catalogs" {
  type = map(object({
    comment        = optional(string, null)
    storage_root   = optional(string, null)
    isolation_mode = optional(string, "OPEN")
    properties     = optional(map(string), {})
    grants = optional(list(object({
      principal  = string
      privileges = list(string)
    })), [])
  }))
  description = <<-EOT
    Map of catalog names to catalog configuration. Each key becomes the catalog name in Unity Catalog.

    - comment        : Human-readable description for the catalog. Null omits the field.
    - storage_root   : Fully-qualified cloud storage path (e.g. s3://bucket/prefix) used as the
                       managed storage root. Null uses the metastore default.
    - isolation_mode : Unity Catalog isolation mode. "OPEN" (default) allows any workspace bound
                       to the metastore to access the catalog. "ISOLATED" restricts access to
                       workspaces explicitly bound to the catalog.
    - properties     : Arbitrary key-value metadata stored on the catalog object.
    - grants         : List of privilege assignments. Each entry specifies a principal (user,
                       group, or service principal) and the list of UC privileges to grant.
  EOT
  nullable    = false
  validation {
    condition = alltrue([
      for name, _ in var.catalogs :
      can(regex("^[a-z][a-z0-9_]{0,254}$", name))
    ])
    error_message = "Each catalog name must start with a lowercase letter, contain only lowercase letters, digits, and underscores, and be at most 255 characters."
  }
  validation {
    condition = alltrue([
      for name, cfg in var.catalogs :
      cfg.isolation_mode == null || contains(["OPEN", "ISOLATED"], cfg.isolation_mode)
    ])
    error_message = "isolation_mode must be \"OPEN\" or \"ISOLATED\"."
  }
}

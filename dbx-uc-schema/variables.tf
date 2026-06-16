variable "catalog_name" {
  type        = string
  description = "Name of the Unity Catalog catalog in which schemas are created. Must already exist."
  nullable    = false
  validation {
    # UC catalog naming: lowercase letters, digits, underscores; starts with a letter; max 255 chars.
    # Validates at plan time to catch obvious typos before an apply-time API error.
    condition     = can(regex("^[a-z][a-z0-9_]{0,254}$", var.catalog_name))
    error_message = "catalog_name must start with a lowercase letter, contain only lowercase letters, digits, and underscores, and be at most 255 characters."
  }
}

variable "schemas" {
  type = map(object({
    comment      = optional(string, null)
    storage_root = optional(string, null)
    properties   = optional(map(string), {})
    grants = optional(list(object({
      principal  = string
      privileges = list(string)
    })), [])
  }))
  description = <<-EOT
    Map of schema names to schema configuration. Each key becomes the schema name in Unity Catalog.

    - comment      : Human-readable description for the schema. Null omits the field.
    - storage_root : Fully-qualified cloud storage path (e.g. s3://bucket/prefix/schema) used as
                     the managed storage root for tables in this schema. Null uses the catalog default.
    - properties   : Arbitrary key-value metadata stored on the schema object.
    - grants       : List of privilege assignments. Each entry specifies a principal (user,
                     group, or service principal) and the list of UC privileges to grant.
                     databricks_grants is authoritative: it replaces the full privilege set each apply.
  EOT
  nullable    = false
  validation {
    # UC schema naming: same rules as catalog names.
    condition = alltrue([
      for name, _ in var.schemas :
      can(regex("^[a-z][a-z0-9_]{0,254}$", name))
    ])
    error_message = "Each schema name must start with a lowercase letter, contain only lowercase letters, digits, and underscores, and be at most 255 characters."
  }
}

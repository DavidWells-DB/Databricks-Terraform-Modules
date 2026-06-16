variable "workspace_id" {
  type        = number
  description = "Databricks workspace ID to assign principals to. Obtained from the workspace creation module or a data source."
  nullable    = false
}

variable "assignments" {
  type = map(object({
    principal_id = number
    roles        = list(string)
  }))
  description = <<-EOT
    Map of workspace permission assignments. Each key is a human-readable label (used as the for_each key).
    Each value contains:
      - principal_id: Databricks account-level principal ID (group, service principal, or user).
      - roles: List of workspace roles to assign. Valid values are "USER" and "ADMIN".
    Example:
      {
        data_eng_group = { principal_id = 123456789, roles = ["USER"] }
        workspace_admin = { principal_id = 987654321, roles = ["ADMIN"] }
      }
  EOT
  nullable    = false

  validation {
    condition = alltrue([
      for k, v in var.assignments : length(v.roles) > 0
    ])
    error_message = "Each assignment must specify at least one role."
  }

  validation {
    condition = alltrue([
      for k, v in var.assignments : alltrue([
        for r in v.roles : contains(["USER", "ADMIN"], r)
      ])
    ])
    error_message = "Valid roles are \"USER\" and \"ADMIN\"."
  }
}

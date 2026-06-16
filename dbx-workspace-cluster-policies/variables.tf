variable "policies" {
  type = map(object({
    # Exactly one of definition or policy_family_id must be provided per policy entry.
    # Use definition for fully custom JSON policy definitions.
    # Use policy_family_id (+ optional overrides) to inherit from a Databricks policy family.
    description = optional(string)
    definition  = optional(string)
    # policy_family_id values are defined by Databricks and returned by the
    # GET /api/2.0/policies/clusters/policy-families API endpoint.
    policy_family_id = optional(string)
    # JSON string of overrides applied on top of the inherited policy family definition.
    policy_family_definition_overrides = optional(string)
    max_clusters_per_user              = optional(number)
  }))
  description = <<-EOT
    Map of cluster policy name to its configuration. Map key becomes the policy name.
    Provide exactly one of `definition` or `policy_family_id` per entry:
    - `definition`: JSON-encoded policy rules in Databricks Policy Definition Language.
    - `policy_family_id`: ID of a Databricks-managed policy family to inherit from.
      Use `policy_family_definition_overrides` (JSON string) to override specific fields.
    - `description`: Optional human-readable description.
    - `max_clusters_per_user`: Optional integer limit on clusters per user (> 0).
  EOT
  nullable    = false

  validation {
    condition = alltrue([
      for k, v in var.policies : (
        # Exactly one of definition or policy_family_id must be set
        (v.definition != null) != (v.policy_family_id != null)
      )
    ])
    error_message = "Each policy entry must have exactly one of `definition` or `policy_family_id` set, not both and not neither."
  }

  validation {
    condition = alltrue([
      for k, v in var.policies : (
        # policy_family_definition_overrides only valid with policy_family_id
        v.policy_family_definition_overrides == null || v.policy_family_id != null
      )
    ])
    error_message = "policy_family_definition_overrides may only be set when policy_family_id is also set."
  }

  validation {
    condition = alltrue([
      for k, v in var.policies : (
        v.max_clusters_per_user == null || v.max_clusters_per_user > 0
      )
    ])
    error_message = "max_clusters_per_user must be greater than 0 when specified."
  }

  validation {
    condition = alltrue([
      for k, _ in var.policies : (
        length(k) >= 1 && length(k) <= 100
      )
    ])
    error_message = "Policy name (map key) must be between 1 and 100 characters."
  }
}

variable "policy_assignments" {
  type = map(object({
    # List of principals (group names, user names, or service principal names)
    # granted CAN_USE on this policy. Each entry is an object with exactly one
    # of group_name, user_name, or service_principal_name.
    access_controls = list(object({
      group_name             = optional(string)
      user_name              = optional(string)
      service_principal_name = optional(string)
    }))
  }))
  description = <<-EOT
    Map of policy name to its permission assignments. Map keys must match keys in `policies`.
    Each entry's `access_controls` is a list of principals granted CAN_USE on that policy.
    Each principal object must set exactly one of `group_name`, `user_name`, or `service_principal_name`.
    Policies not present in this map receive no explicit permissions (Databricks default applies).
  EOT
  default     = {}
  nullable    = false

  validation {
    condition = alltrue([
      for policy_name, assignment in var.policy_assignments : alltrue([
        for ac in assignment.access_controls : (
          # Exactly one principal selector must be set
          length([for v in [ac.group_name, ac.user_name, ac.service_principal_name] : v if v != null]) == 1
        )
      ])
    ])
    error_message = "Each access_control entry must set exactly one of group_name, user_name, or service_principal_name."
  }
}

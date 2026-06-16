variable "access_policy_id" {
  type        = string
  description = "Existing Access Context Manager access policy ID (organization-level). Format: accessPolicies/<policy_id> or <policy_id>."
  nullable    = false
}

variable "perimeter_name" {
  type        = string
  description = "Name of the service perimeter. Must be alphanumeric with underscores, max 50 chars."
  nullable    = false
  validation {
    condition     = length(var.perimeter_name) >= 1 && length(var.perimeter_name) <= 50 && can(regex("^[A-Za-z0-9_]+$", var.perimeter_name))
    error_message = "perimeter_name must be 1-50 characters and contain only alphanumeric characters and underscores."
  }
}

variable "perimeter_title" {
  type        = string
  description = "Human-readable title for the service perimeter."
  nullable    = false
  validation {
    condition     = length(var.perimeter_title) >= 1 && length(var.perimeter_title) <= 200
    error_message = "perimeter_title must be 1-200 characters."
  }
}

variable "protected_project_numbers" {
  type        = list(string)
  description = "List of GCP project numbers to include in the perimeter. Format: \"projects/<project_number>\" or \"<project_number>\"."
  nullable    = false
  validation {
    condition     = length(var.protected_project_numbers) >= 1
    error_message = "At least one protected project number must be specified."
  }
}

variable "restricted_services" {
  type        = list(string)
  description = "List of GCP services restricted by the perimeter (e.g., \"storage.googleapis.com\", \"bigquery.googleapis.com\")."
  default     = ["storage.googleapis.com", "bigquery.googleapis.com"]
  nullable    = false
}

variable "access_levels" {
  type        = list(string)
  description = "List of access level resource names to allow ingress. Format: accessPolicies/<policy_id>/accessLevels/<level_name>."
  default     = []
  nullable    = false
}

variable "ingress_policies" {
  type = list(object({
    ingress_from = optional(object({
      sources = optional(list(object({
        access_level = optional(string)
        resource     = optional(string)
      })), [])
      identity_type = optional(string)
      identities    = optional(list(string), [])
    }))
    ingress_to = optional(object({
      resources = optional(list(string), [])
      operations = optional(list(object({
        service_name = optional(string)
        method_selectors = optional(list(object({
          method     = optional(string)
          permission = optional(string)
        })), [])
      })), [])
    }))
  }))
  description = "Ingress policy rules for the perimeter. See https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/access_context_manager_service_perimeter#ingress_policies for structure."
  default     = []
  nullable    = false
}

variable "egress_policies" {
  type = list(object({
    egress_from = optional(object({
      identity_type = optional(string)
      identities    = optional(list(string), [])
    }))
    egress_to = optional(object({
      resources = optional(list(string), [])
      operations = optional(list(object({
        service_name = optional(string)
        method_selectors = optional(list(object({
          method     = optional(string)
          permission = optional(string)
        })), [])
      })), [])
    }))
  }))
  description = "Egress policy rules for the perimeter. See https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/access_context_manager_service_perimeter#egress_policies for structure."
  default     = []
  nullable    = false
}

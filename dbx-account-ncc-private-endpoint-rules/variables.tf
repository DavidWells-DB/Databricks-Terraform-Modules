variable "network_connectivity_config_id" {
  type        = string
  description = "NCC that owns these private endpoint rules."
  nullable    = false

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.network_connectivity_config_id))
    error_message = "network_connectivity_config_id must be an NCC UUID."
  }
}

variable "cloud" {
  type        = string
  description = "Cloud whose private endpoint fields are required: aws or azure."
  nullable    = false

  validation {
    condition     = contains(["aws", "azure"], var.cloud)
    error_message = "cloud must be aws or azure."
  }
}

variable "private_endpoint_rules" {
  type = list(object({
    key              = string
    resource_id      = optional(string)
    group_id         = optional(string)
    endpoint_service = optional(string)
    resource_names   = optional(list(string))
    enabled          = optional(bool, true)
    domain_names     = optional(list(string))
  }))
  description = "Private endpoint rules with stable caller-selected keys. Azure uses resource_id + group_id or domain_names; AWS uses endpoint_service + resource_names or domain_names."
  default     = []
  nullable    = false

  validation {
    condition     = length(var.private_endpoint_rules) == length(toset([for r in var.private_endpoint_rules : r.key]))
    error_message = "Each private_endpoint_rules entry must have a unique key."
  }

  validation {
    condition = alltrue([for r in var.private_endpoint_rules :
      var.cloud != "azure" || (
        (r.resource_id != null && r.group_id != null && r.domain_names == null) ||
        (r.domain_names != null && r.group_id == null)
      )
    ])
    error_message = "Azure rules require resource_id + group_id, or domain_names without group_id."
  }

  validation {
    condition = alltrue([for r in var.private_endpoint_rules :
      var.cloud != "aws" || (
        (r.endpoint_service != null && r.resource_names != null && r.domain_names == null) ||
        (r.domain_names != null && r.resource_names == null)
      )
    ])
    error_message = "AWS rules require endpoint_service + resource_names, or domain_names without resource_names."
  }
}

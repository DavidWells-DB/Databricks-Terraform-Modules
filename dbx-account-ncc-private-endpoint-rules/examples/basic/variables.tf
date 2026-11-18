variable "network_connectivity_config_id" { type = string }
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
}

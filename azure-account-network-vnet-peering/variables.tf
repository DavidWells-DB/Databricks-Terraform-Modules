variable "local_vnet_name" {
  type        = string
  description = "Name of the local (initiating) virtual network."
  nullable    = false
  validation {
    # Azure VNet name: 2-64 chars, alphanumeric, hyphens, or underscores, must start/end with alphanumeric.
    # https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules#microsoftnetwork
    condition     = length(var.local_vnet_name) >= 2 && length(var.local_vnet_name) <= 64 && can(regex("^[a-zA-Z0-9][a-zA-Z0-9_-]*[a-zA-Z0-9]$|^[a-zA-Z0-9]$", var.local_vnet_name))
    error_message = "local_vnet_name must be 2-64 characters, start and end with alphanumeric, and contain only alphanumeric, hyphen, or underscore characters."
  }
}

variable "remote_vnet_name" {
  type        = string
  description = "Name of the remote (target) virtual network."
  nullable    = false
  validation {
    # Azure VNet name: 2-64 chars, alphanumeric, hyphens, or underscores, must start/end with alphanumeric.
    # https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules#microsoftnetwork
    condition     = length(var.remote_vnet_name) >= 2 && length(var.remote_vnet_name) <= 64 && can(regex("^[a-zA-Z0-9][a-zA-Z0-9_-]*[a-zA-Z0-9]$|^[a-zA-Z0-9]$", var.remote_vnet_name))
    error_message = "remote_vnet_name must be 2-64 characters, start and end with alphanumeric, and contain only alphanumeric, hyphen, or underscore characters."
  }
}

variable "local_vnet_id" {
  type        = string
  description = "Full Azure resource ID of the local virtual network."
  nullable    = false
  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.Network/virtualNetworks/[^/]+$", var.local_vnet_id))
    error_message = "local_vnet_id must be a valid Azure VNet resource ID in the form /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Network/virtualNetworks/{name}."
  }
}

variable "remote_vnet_id" {
  type        = string
  description = "Full Azure resource ID of the remote virtual network."
  nullable    = false
  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.Network/virtualNetworks/[^/]+$", var.remote_vnet_id))
    error_message = "remote_vnet_id must be a valid Azure VNet resource ID in the form /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Network/virtualNetworks/{name}."
  }
}

variable "local_resource_group_name" {
  type        = string
  description = "Name of the resource group containing the local virtual network."
  nullable    = false
  validation {
    # Azure resource group name: 1-90 chars, alphanumeric, underscores, hyphens, periods, parentheses.
    condition     = length(var.local_resource_group_name) >= 1 && length(var.local_resource_group_name) <= 90 && can(regex("^[a-zA-Z0-9_()\\-\\.]+$", var.local_resource_group_name))
    error_message = "local_resource_group_name must be 1-90 characters and contain only alphanumeric, underscore, hyphen, period, or parenthesis characters."
  }
}

variable "remote_resource_group_name" {
  type        = string
  description = "Name of the resource group containing the remote virtual network."
  nullable    = false
  validation {
    # Azure resource group name: 1-90 chars, alphanumeric, underscores, hyphens, periods, parentheses.
    condition     = length(var.remote_resource_group_name) >= 1 && length(var.remote_resource_group_name) <= 90 && can(regex("^[a-zA-Z0-9_()\\-\\.]+$", var.remote_resource_group_name))
    error_message = "remote_resource_group_name must be 1-90 characters and contain only alphanumeric, underscore, hyphen, period, or parenthesis characters."
  }
}

variable "allow_virtual_network_access" {
  type        = bool
  description = "Allow VMs in the remote VNet to access VMs in the local VNet and vice versa. Applies to both peering directions."
  default     = true
}

variable "allow_forwarded_traffic" {
  type        = bool
  description = "Allow forwarded traffic from VMs in the remote VNet into the local VNet and vice versa. Applies to both peering directions."
  default     = false
}

variable "allow_gateway_transit" {
  type        = bool
  description = "Allow the local VNet to use the remote VNet's gateway or route server. Set to true on the hub VNet that owns the gateway. Applies to the local-to-remote peering only."
  default     = false
}

variable "use_remote_gateways" {
  type        = bool
  description = "Allow the local VNet to use the remote VNet's gateway or route server. Cannot be set to true if allow_gateway_transit is also true. Applies to the local-to-remote peering only."
  default     = false
  validation {
    condition     = !(var.use_remote_gateways && var.allow_gateway_transit)
    error_message = "use_remote_gateways and allow_gateway_transit cannot both be true — they represent opposite roles in a gateway peering relationship."
  }
}

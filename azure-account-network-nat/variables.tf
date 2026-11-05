variable "resource_group_name" {
  type        = string
  description = "Name of the Azure resource group for the NAT gateway and public IP."
  nullable    = false
  validation {
    # https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules
    condition     = length(var.resource_group_name) >= 1 && length(var.resource_group_name) <= 90 && can(regex("^[A-Za-z0-9_.()-]+[A-Za-z0-9_()-]$", var.resource_group_name))
    error_message = "resource_group_name must be 1-90 characters, may contain alphanumeric, underscore, hyphen, period, and parentheses, and must not end with a period."
  }
}

variable "location" {
  type        = string
  description = "Azure region for the NAT gateway (e.g. \"eastus\"). Must match the resource group's region."
  nullable    = false
}

variable "nat_gateway_name" {
  type        = string
  description = "Name of the NAT gateway."
  nullable    = false
  validation {
    # NAT gateway: 1-80 chars, letters/digits/hyphens/underscores/periods, must start with a letter or digit.
    condition     = length(var.nat_gateway_name) >= 1 && length(var.nat_gateway_name) <= 80 && can(regex("^[A-Za-z0-9][A-Za-z0-9_.-]*$", var.nat_gateway_name))
    error_message = "nat_gateway_name must be 1-80 characters, start with a letter or digit, and contain only letters, digits, periods, hyphens, and underscores."
  }
}

variable "public_ip_name" {
  type        = string
  description = "Name of the Standard-SKU public IP that fronts the NAT gateway."
  nullable    = false
  validation {
    condition     = length(var.public_ip_name) >= 1 && length(var.public_ip_name) <= 80 && can(regex("^[A-Za-z0-9][A-Za-z0-9_.-]*$", var.public_ip_name))
    error_message = "public_ip_name must be 1-80 characters, start with a letter or digit, and contain only letters, digits, periods, hyphens, and underscores."
  }
}

variable "subnets" {
  type        = map(string)
  description = "Map of caller-chosen association names to subnet resource IDs that should egress via the NAT gateway (e.g. { host = module.vnet.host_subnet_id, container = module.vnet.container_subnet_id }). The KEYS are plan-time constants — that is why this is a map, not a list (for_each over a list of known-after-apply subnet IDs fails at apply)."
  nullable    = false
  validation {
    condition     = length(var.subnets) >= 1
    error_message = "At least one subnet ID is required — a NAT gateway with no subnet associations provides no egress."
  }
  validation {
    condition     = alltrue([for _, id in var.subnets : can(regex("^/subscriptions/.+/subnets/.+$", id))])
    error_message = "Each value in subnets must be an Azure subnet resource ID (/subscriptions/<sub>/.../subnets/<name>)."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the NAT gateway and public IP."
  default     = {}
}

variable "resource_group_name" {
  type        = string
  description = "Name of the Azure resource group in which to create the VNet and subnets."
  nullable    = false
  validation {
    # Azure resource group name: 1-90 chars, alphanumeric, underscore, hyphen, period (cannot end with period)
    # https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules
    condition     = length(var.resource_group_name) >= 1 && length(var.resource_group_name) <= 90 && can(regex("^[A-Za-z0-9_.()-]+[A-Za-z0-9_()-]$", var.resource_group_name))
    error_message = "resource_group_name must be 1-90 characters, may contain alphanumeric, underscore, hyphen, period, and parentheses, and must not end with a period."
  }
}

variable "location" {
  type        = string
  description = "Azure region where the VNet and subnets are created (e.g. \"eastus\", \"westeurope\"). Must match the resource group's region."
  nullable    = false
  validation {
    # Require non-empty string; Azure region values are provider-validated at apply time.
    condition     = length(trimspace(var.location)) > 0
    error_message = "location must be a non-empty Azure region string."
  }
}

variable "vnet_name" {
  type        = string
  description = "Name for the Azure Virtual Network."
  nullable    = false
  validation {
    # Azure VNet name: 2-64 chars, alphanumeric, underscore, hyphen, period
    # https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules
    condition     = length(var.vnet_name) >= 2 && length(var.vnet_name) <= 64 && can(regex("^[A-Za-z0-9][A-Za-z0-9_.-]*[A-Za-z0-9_]$", var.vnet_name))
    error_message = "vnet_name must be 2-64 characters, start and end with alphanumeric or underscore, and contain only alphanumeric, underscore, hyphen, or period characters."
  }
}

variable "vnet_cidr" {
  type        = string
  description = "CIDR block for the Virtual Network address space (e.g. \"10.0.0.0/16\"). Must be large enough to accommodate the host, container, and optional PE subnets."
  nullable    = false
  validation {
    condition     = can(cidrhost(var.vnet_cidr, 0))
    error_message = "vnet_cidr must be a valid CIDR block (e.g. \"10.0.0.0/16\")."
  }
}

variable "host_subnet_name" {
  type        = string
  description = "Name for the Databricks host (compute) subnet. Must not be \"AzureBastionSubnet\" or \"GatewaySubnet\" — those are reserved Azure names."
  nullable    = false
  validation {
    # Azure subnet name: 1-80 chars, alphanumeric, underscore, hyphen, period
    condition     = length(var.host_subnet_name) >= 1 && length(var.host_subnet_name) <= 80 && can(regex("^[A-Za-z0-9][A-Za-z0-9_.-]*$", var.host_subnet_name))
    error_message = "host_subnet_name must be 1-80 characters and start with alphanumeric; may contain alphanumeric, underscore, hyphen, or period."
  }
}

variable "host_subnet_cidr" {
  type        = string
  description = "CIDR block for the Databricks host subnet (e.g. \"10.0.1.0/24\"). Must be a subset of vnet_cidr and at least /26."
  nullable    = false
  validation {
    condition     = can(cidrhost(var.host_subnet_cidr, 0))
    error_message = "host_subnet_cidr must be a valid CIDR block (e.g. \"10.0.1.0/24\")."
  }
}

variable "container_subnet_name" {
  type        = string
  description = "Name for the Databricks container subnet."
  nullable    = false
  validation {
    # Azure subnet name: 1-80 chars, alphanumeric, underscore, hyphen, period
    condition     = length(var.container_subnet_name) >= 1 && length(var.container_subnet_name) <= 80 && can(regex("^[A-Za-z0-9][A-Za-z0-9_.-]*$", var.container_subnet_name))
    error_message = "container_subnet_name must be 1-80 characters and start with alphanumeric; may contain alphanumeric, underscore, hyphen, or period."
  }
}

variable "container_subnet_cidr" {
  type        = string
  description = "CIDR block for the Databricks container subnet (e.g. \"10.0.2.0/24\"). Must be a subset of vnet_cidr and at least /26."
  nullable    = false
  validation {
    condition     = can(cidrhost(var.container_subnet_cidr, 0))
    error_message = "container_subnet_cidr must be a valid CIDR block (e.g. \"10.0.2.0/24\")."
  }
}

variable "pe_subnet_name" {
  type        = string
  description = "Name for the optional private endpoint subnet. Set to null to skip private endpoint subnet creation."
  default     = null
  nullable    = true
  validation {
    # When provided, Azure subnet name: 1-80 chars, alphanumeric, underscore, hyphen, period
    condition     = var.pe_subnet_name == null || (length(var.pe_subnet_name) >= 1 && length(var.pe_subnet_name) <= 80 && can(regex("^[A-Za-z0-9][A-Za-z0-9_.-]*$", var.pe_subnet_name)))
    error_message = "pe_subnet_name must be null or a 1-80 character string starting with alphanumeric; may contain alphanumeric, underscore, hyphen, or period."
  }
}

variable "pe_subnet_cidr" {
  type        = string
  description = "CIDR block for the optional private endpoint subnet (e.g. \"10.0.3.0/27\"). Required when pe_subnet_name is set; ignored when pe_subnet_name is null."
  default     = null
  nullable    = true
  validation {
    condition     = var.pe_subnet_cidr == null || can(cidrhost(var.pe_subnet_cidr, 0))
    error_message = "pe_subnet_cidr must be null or a valid CIDR block (e.g. \"10.0.3.0/27\")."
  }
}

variable "nsg_name" {
  type        = string
  description = "Name for the Network Security Group applied to both Databricks subnets. A single NSG is shared between host and container subnets as required by Databricks VNet injection."
  nullable    = false
  validation {
    # Azure NSG name: 1-80 chars, alphanumeric, underscore, hyphen, period
    condition     = length(var.nsg_name) >= 1 && length(var.nsg_name) <= 80 && can(regex("^[A-Za-z0-9][A-Za-z0-9_.-]*$", var.nsg_name))
    error_message = "nsg_name must be 1-80 characters and start with alphanumeric; may contain alphanumeric, underscore, hyphen, or period."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all Azure resources created by this module."
  default     = {}
}

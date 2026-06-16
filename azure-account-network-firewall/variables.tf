variable "resource_group_name" {
  type        = string
  description = "Name of the Azure resource group in which to create all firewall resources."
  nullable    = false
  validation {
    # Azure resource group name: 1-90 chars, alphanumeric, underscore, hyphen, period, parentheses; cannot end with period.
    # https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules
    condition     = length(var.resource_group_name) >= 1 && length(var.resource_group_name) <= 90 && can(regex("^[A-Za-z0-9_.()-]+[A-Za-z0-9_()-]$", var.resource_group_name))
    error_message = "resource_group_name must be 1-90 characters, may contain alphanumeric, underscore, hyphen, period, and parentheses, and must not end with a period."
  }
}

variable "location" {
  type        = string
  description = "Azure region where all firewall resources are created (e.g. \"eastus\", \"westeurope\"). Must match the resource group's region."
  nullable    = false
  validation {
    # Require non-empty string; Azure region values are provider-validated at apply time.
    condition     = length(trimspace(var.location)) > 0
    error_message = "location must be a non-empty Azure region string."
  }
}

variable "firewall_name" {
  type        = string
  description = "Name for the Azure Firewall. Used as the base name for the firewall, policy, IP group, public IP, and route table resources."
  nullable    = false
  validation {
    # Azure Firewall name: 1-56 chars, alphanumeric, hyphen, underscore.
    # Must start and end with alphanumeric or underscore (single-char names are allowed).
    # https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules
    condition     = length(var.firewall_name) >= 1 && length(var.firewall_name) <= 56 && can(regex("^[A-Za-z0-9_][A-Za-z0-9_-]*[A-Za-z0-9_]$|^[A-Za-z0-9_]$", var.firewall_name))
    error_message = "firewall_name must be 1-56 characters, start and end with alphanumeric or underscore, and contain only alphanumeric, hyphen, or underscore characters."
  }
}

variable "firewall_subnet_id" {
  type        = string
  description = "Resource ID of the AzureFirewallSubnet into which the firewall is deployed. The subnet must be named exactly \"AzureFirewallSubnet\" and be at least /26."
  nullable    = false
  validation {
    # Azure subnet resource IDs follow a well-known path pattern.
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.Network/virtualNetworks/[^/]+/subnets/[^/]+$", var.firewall_subnet_id))
    error_message = "firewall_subnet_id must be a valid Azure subnet resource ID (e.g. /subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/.../subnets/AzureFirewallSubnet)."
  }
}

variable "spoke_subnet_ids" {
  type        = list(string)
  description = "List of spoke subnet resource IDs whose egress should be forced through the firewall. A forced-tunnel route table (0.0.0.0/0 → firewall private IP) is created and associated with each subnet. At least one subnet ID is required."
  nullable    = false
  validation {
    condition     = length(var.spoke_subnet_ids) >= 1
    error_message = "At least one spoke subnet ID is required."
  }
  validation {
    condition     = alltrue([for id in var.spoke_subnet_ids : can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.Network/virtualNetworks/[^/]+/subnets/[^/]+$", id))])
    error_message = "Each entry in spoke_subnet_ids must be a valid Azure subnet resource ID."
  }
}

variable "allowed_spoke_cidr_ranges" {
  type        = list(string)
  description = "List of CIDR ranges for spoke VNet subnets. Used to populate the source IP group in the firewall network rules that permit spoke egress traffic through the firewall."
  nullable    = false
  validation {
    condition     = length(var.allowed_spoke_cidr_ranges) >= 1
    error_message = "At least one spoke CIDR range is required."
  }
  validation {
    condition     = alltrue([for cidr in var.allowed_spoke_cidr_ranges : can(cidrhost(cidr, 0))])
    error_message = "Each entry in allowed_spoke_cidr_ranges must be a valid CIDR block (e.g. \"10.0.0.0/16\")."
  }
}

variable "service_tag_rules" {
  type = list(object({
    name              = string
    priority          = number
    action            = string
    destination_tags  = list(string)
    destination_ports = list(string)
    protocols         = list(string)
  }))
  description = <<-EOT
    List of network rule objects that permit traffic from spoke subnets to Databricks-specific
    Azure service tags. Each rule targets a set of Azure service tags (e.g. ["AzureDatabricks",
    "Storage.EastUs"]) on the specified ports and protocols. Priority must be unique per rule
    within the rule collection group and in the range 100-65000. Action must be "Allow" or "Deny".
    Protocols must each be one of "Any", "TCP", "UDP", "ICMP".
  EOT
  nullable    = false
  validation {
    condition     = length(var.service_tag_rules) >= 1
    error_message = "At least one service tag rule is required."
  }
  validation {
    condition     = alltrue([for r in var.service_tag_rules : r.priority >= 100 && r.priority <= 65000])
    error_message = "Each service_tag_rules entry priority must be between 100 and 65000."
  }
  validation {
    condition     = alltrue([for r in var.service_tag_rules : contains(["Allow", "Deny"], r.action)])
    error_message = "Each service_tag_rules entry action must be \"Allow\" or \"Deny\"."
  }
  validation {
    condition     = alltrue([for r in var.service_tag_rules : alltrue([for p in r.protocols : contains(["Any", "TCP", "UDP", "ICMP"], p)])])
    error_message = "Each service_tag_rules entry protocol must be one of \"Any\", \"TCP\", \"UDP\", \"ICMP\"."
  }
}

variable "firewall_sku_tier" {
  type        = string
  description = "SKU tier for the Azure Firewall and its policy. \"Standard\" or \"Premium\". Premium enables TLS inspection and IDPS; recommended for SNI-based Databricks egress filtering."
  default     = "Premium"
  nullable    = false
  validation {
    condition     = contains(["Standard", "Premium"], var.firewall_sku_tier)
    error_message = "firewall_sku_tier must be \"Standard\" or \"Premium\"."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all Azure resources created by this module."
  default     = {}
}

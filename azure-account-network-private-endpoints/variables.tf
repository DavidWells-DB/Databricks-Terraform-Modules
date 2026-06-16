variable "resource_group_name" {
  type        = string
  description = "Name of the Azure resource group in which to create private endpoint and DNS resources."
  nullable    = false
  validation {
    # Azure resource group name: 1-90 chars, alphanumeric, underscores, parentheses, hyphens, and periods.
    # Must not end with a period.
    # Source: https://learn.microsoft.com/azure/azure-resource-manager/management/resource-name-rules
    condition     = length(var.resource_group_name) >= 1 && length(var.resource_group_name) <= 90 && can(regex("^[A-Za-z0-9_().\\-]+[^.]$", var.resource_group_name))
    error_message = "resource_group_name must be 1-90 characters, contain only alphanumeric, underscore, parentheses, hyphen, or period, and must not end with a period."
  }
}

variable "location" {
  type        = string
  description = "Azure region for private endpoint resources (e.g., \"eastus\", \"westeurope\"). Must match the region of the Databricks workspace."
  nullable    = false
  validation {
    # Azure location values are lowercase alphanumeric with no spaces.
    condition     = can(regex("^[a-z0-9]+$", var.location))
    error_message = "location must be a lowercase alphanumeric Azure region name (e.g., \"eastus\", \"westeurope\")."
  }
}

variable "workspace_resource_id" {
  type        = string
  description = "Azure resource ID of the Databricks workspace (e.g., /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Databricks/workspaces/<name>)."
  nullable    = false
  validation {
    # Must be a Databricks workspace resource ID.
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.Databricks/workspaces/[^/]+$", var.workspace_resource_id))
    error_message = "workspace_resource_id must be a valid Azure Databricks workspace resource ID of the form /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Databricks/workspaces/<name>."
  }
}

variable "pe_subnet_id" {
  type        = string
  description = "Azure resource ID of the subnet in which to place private endpoint network interfaces. Private endpoint network policies must be disabled on this subnet."
  nullable    = false
  validation {
    # Must be a valid subnet resource ID.
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.Network/virtualNetworks/[^/]+/subnets/[^/]+$", var.pe_subnet_id))
    error_message = "pe_subnet_id must be a valid Azure subnet resource ID."
  }
}

variable "vnet_id" {
  type        = string
  description = "Azure resource ID of the VNet to link to the private DNS zone. This is the spoke VNet that contains the Databricks subnets."
  nullable    = false
  validation {
    # Must be a valid VNet resource ID.
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.Network/virtualNetworks/[^/]+$", var.vnet_id))
    error_message = "vnet_id must be a valid Azure VNet resource ID."
  }
}

variable "enable_front_end_pe" {
  type        = bool
  description = "When true, creates an additional front-end private endpoint (sub-resource type `databricks_ui_api` on the `publicFrontEnd` group). Required when public network access is disabled and clients access Databricks from outside the injected VNet."
  default     = false
  nullable    = false
}

variable "enable_browser_auth_pe" {
  type        = bool
  description = "When true, creates a browser_authentication private endpoint. Required for SSO callback flows (web browser authentication) when public network access is disabled."
  default     = false
  nullable    = false
}

variable "hub_vnet_ids" {
  type        = list(string)
  description = "Optional list of hub VNet resource IDs to also link to the private DNS zone. Use when the DNS zone lives in the spoke but hub VNets must resolve the workspace URL. Defaults to an empty list (no hub links)."
  default     = []
  nullable    = false
  validation {
    # Each entry must be a valid VNet resource ID.
    condition = alltrue([
      for id in var.hub_vnet_ids :
      can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.Network/virtualNetworks/[^/]+$", id))
    ])
    error_message = "Each entry in hub_vnet_ids must be a valid Azure VNet resource ID."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources created by this module."
  default     = {}
}

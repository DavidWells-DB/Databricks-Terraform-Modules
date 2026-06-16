variable "name" {
  type        = string
  description = "Name of the Azure Databricks workspace resource. Must be unique within the resource group."
  nullable    = false
  validation {
    # AzureRM name constraint: 3-64 chars, alphanumeric + hyphens; must start/end with alphanumeric.
    # https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules
    condition     = length(var.name) >= 3 && length(var.name) <= 64 && can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.name))
    error_message = "name must be 3-64 characters, alphanumeric and hyphens only, starting and ending with an alphanumeric character."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Name of the Azure resource group in which to create the Databricks workspace."
  nullable    = false
}

variable "location" {
  type        = string
  description = "Azure region for the workspace (e.g., \"eastus\", \"westeurope\"). Must match the resource group region."
  nullable    = false
}

variable "sku" {
  type        = string
  description = "Databricks workspace SKU. Use \"premium\" for Unity Catalog, IP access lists, cluster policies with ACLs, and all Premium features. Use \"standard\" for basic workspaces only."
  default     = "premium"
  validation {
    condition     = contains(["standard", "premium", "trial"], var.sku)
    error_message = "sku must be \"standard\", \"premium\", or \"trial\"."
  }
}

variable "managed_resource_group_name" {
  type        = string
  description = "Optional name for the managed resource group that Azure Databricks creates for control-plane resources. If null, Azure generates a name automatically."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the Azure Databricks workspace resource."
  default     = {}
}

# VNet injection inputs (optional — all must be set together or all null)

variable "virtual_network_id" {
  type        = string
  description = "Resource ID of the Azure VNet for VNet injection. When set, host_subnet_name and container_subnet_name must also be set."
  default     = null
}

variable "host_subnet_name" {
  type        = string
  description = "Name of the public (host) subnet within the VNet for VNet injection. Required when virtual_network_id is set."
  default     = null
}

variable "container_subnet_name" {
  type        = string
  description = "Name of the private (container) subnet within the VNet for VNet injection. Required when virtual_network_id is set."
  default     = null
}

variable "public_subnet_network_security_group_association_id" {
  type        = string
  description = "Resource ID of the NSG association for the public (host) subnet. Required when virtual_network_id is set."
  default     = null
}

variable "private_subnet_network_security_group_association_id" {
  type        = string
  description = "Resource ID of the NSG association for the private (container) subnet. Required when virtual_network_id is set."
  default     = null
}

variable "no_public_ip" {
  type        = bool
  description = "Enable Secure Cluster Connectivity (SCC / No Public IP). When true, cluster nodes have no public IPs. Recommended for production. Requires VNet injection."
  default     = false
}

# Network access

variable "public_network_access_enabled" {
  type        = bool
  description = "Allow public network access to the workspace front-end. Set to false to require private connectivity only."
  default     = true
}

variable "network_security_group_rules_required" {
  type        = string
  description = "Determines NSG rule enforcement. Valid values: \"AllRules\", \"NoAzureDatabricksRules\", \"NoAzureServiceRules\". Typically \"AllRules\" for VNet injection; null defers to Azure default."
  default     = null
  validation {
    condition     = var.network_security_group_rules_required == null || contains(["AllRules", "NoAzureDatabricksRules", "NoAzureServiceRules"], var.network_security_group_rules_required)
    error_message = "network_security_group_rules_required must be null, \"AllRules\", \"NoAzureDatabricksRules\", or \"NoAzureServiceRules\"."
  }
}

# Customer-managed keys

variable "managed_services_cmk_key_vault_key_id" {
  type        = string
  description = "Key Vault key ID for managed services (notebooks, artifacts) encryption. Requires customer_managed_key_enabled = true and premium SKU."
  default     = null
}

variable "managed_disk_cmk_key_vault_key_id" {
  type        = string
  description = "Key Vault key ID for managed disk encryption. Requires premium SKU."
  default     = null
}

variable "managed_disk_cmk_rotation_to_latest_version_enabled" {
  type        = bool
  description = "Automatically rotate managed disk CMK to the latest key version. Only relevant when managed_disk_cmk_key_vault_key_id is set."
  default     = false
}

variable "customer_managed_key_enabled" {
  type        = bool
  description = "Enable customer-managed key for managed services encryption. Requires premium SKU and managed_services_cmk_key_vault_key_id."
  default     = false
}

variable "infrastructure_encryption_enabled" {
  type        = bool
  description = "Enable a secondary layer of encryption for workspace data at rest. Requires premium SKU. Immutable after workspace creation."
  default     = false
}

variable "root_dbfs_cmk_key_vault_key_id" {
  type        = string
  description = "Key Vault key ID for root DBFS encryption via azurerm_databricks_workspace_root_dbfs_customer_managed_key. When set, root DBFS CMK is configured as a post-creation step."
  default     = null
}

variable "root_dbfs_cmk_key_vault_id" {
  type        = string
  description = "Resource ID of the Key Vault containing root_dbfs_cmk_key_vault_key_id. Required only when the Key Vault is in a different subscription than the workspace."
  default     = null
}

# Default storage firewall

variable "default_storage_firewall_enabled" {
  type        = bool
  description = "Disallow public access to the default storage account. When true, access_connector_id must also be set."
  default     = false
}

variable "access_connector_id" {
  type        = string
  description = "Resource ID of the Azure Databricks Access Connector. Required when default_storage_firewall_enabled = true."
  default     = null
}

# Enhanced security and compliance (Enterprise tier features)

variable "automatic_cluster_update_enabled" {
  type        = bool
  description = "Enable automatic cluster update. Part of the Enhanced Security and Compliance add-on. Requires compliance_security_profile_enabled = true when the compliance profile is in use."
  default     = false
}

variable "enhanced_security_monitoring_enabled" {
  type        = bool
  description = "Enable enhanced security monitoring. Part of the Enhanced Security and Compliance add-on."
  default     = false
}

variable "compliance_security_profile_enabled" {
  type        = bool
  description = "Enable the Compliance Security Profile. Permanent for a workspace — cannot be disabled once enabled. Requires the Enhanced Security and Compliance add-on and premium SKU."
  default     = false
}

variable "compliance_security_profile_standards" {
  type        = list(string)
  description = "List of compliance standards to enable. Valid values via azurerm: \"HIPAA\", \"PCI_DSS\", \"NONE\". Other standards (HITRUST, IRAP_PROTECTED, UK_CYBER_ESSENTIALS_PLUS, CANADA_PROTECTED_B) require the azapi workaround (see extended_compliance_standards). Only meaningful when compliance_security_profile_enabled = true."
  default     = []
  validation {
    condition     = length([for s in var.compliance_security_profile_standards : s if !contains(["HIPAA", "PCI_DSS", "NONE"], s)]) == 0
    error_message = "compliance_security_profile_standards (azurerm path) accepts only \"HIPAA\", \"PCI_DSS\", or \"NONE\". For HITRUST, IRAP_PROTECTED, UK_CYBER_ESSENTIALS_PLUS, CANADA_PROTECTED_B use extended_compliance_standards."
  }
}

variable "extended_compliance_standards" {
  type        = list(string)
  description = "Additional compliance standards not supported by the azurerm provider: \"HITRUST\", \"IRAP_PROTECTED\", \"UK_CYBER_ESSENTIALS_PLUS\", \"CANADA_PROTECTED_B\". Applied via azapi_update_resource post-creation. Only meaningful when compliance_security_profile_enabled = true."
  default     = []
  validation {
    condition     = length([for s in var.extended_compliance_standards : s if !contains(["HITRUST", "IRAP_PROTECTED", "UK_CYBER_ESSENTIALS_PLUS", "CANADA_PROTECTED_B"], s)]) == 0
    error_message = "extended_compliance_standards accepts only \"HITRUST\", \"IRAP_PROTECTED\", \"UK_CYBER_ESSENTIALS_PLUS\", or \"CANADA_PROTECTED_B\"."
  }
}

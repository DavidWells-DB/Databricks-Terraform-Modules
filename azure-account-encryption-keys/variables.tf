variable "resource_group_name" {
  type        = string
  description = "Name of the Azure resource group where the Key Vault will be created."
  nullable    = false
}

variable "location" {
  type        = string
  description = "Azure region for the Key Vault (e.g. \"eastus\", \"westeurope\")."
  nullable    = false
}

variable "key_vault_name" {
  type        = string
  description = "Name of the Azure Key Vault. Must be globally unique, 3-24 characters, alphanumeric and hyphens only, start with a letter."
  nullable    = false
  validation {
    # Azure Key Vault name constraint: 3-24 chars, alphanumeric + hyphens, starts with letter.
    # https://learn.microsoft.com/en-us/azure/key-vault/general/about-keys-secrets-certificates#vault-name-and-object-name
    condition     = length(var.key_vault_name) >= 3 && length(var.key_vault_name) <= 24 && can(regex("^[A-Za-z][A-Za-z0-9-]*$", var.key_vault_name)) && !endswith(var.key_vault_name, "-")
    error_message = "key_vault_name must be 3-24 characters, start with a letter, contain only alphanumeric characters and hyphens, and not end with a hyphen."
  }
}

variable "tenant_id" {
  type        = string
  description = "Azure Active Directory tenant ID. Must be a valid UUID."
  nullable    = false
  validation {
    # UUID format validation
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.tenant_id))
    error_message = "tenant_id must be a valid UUID (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)."
  }
}

variable "databricks_service_principal_object_id" {
  type        = string
  description = "Object ID of the AzureDatabricks enterprise application in your Azure AD tenant. Used in the Key Vault access policy granting Databricks permission to wrap/unwrap keys."
  nullable    = false
  validation {
    # UUID format validation
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.databricks_service_principal_object_id))
    error_message = "databricks_service_principal_object_id must be a valid UUID (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)."
  }
}

variable "azure_client_object_id" {
  type        = string
  description = "Object ID of the Azure service principal or user running Terraform. Granted full key management permissions so that Terraform can create and manage keys."
  nullable    = false
  validation {
    # UUID format validation
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.azure_client_object_id))
    error_message = "azure_client_object_id must be a valid UUID (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)."
  }
}

variable "soft_delete_retention_days" {
  type        = number
  description = "Number of days to retain soft-deleted Key Vault objects. Must be between 7 and 90. Required for Premium SKU."
  default     = 7
  nullable    = false
  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "soft_delete_retention_days must be between 7 and 90."
  }
}

variable "private_endpoint" {
  type = object({
    subnet_id           = string
    vnet_id             = string
    resource_group_name = optional(string)
  })
  description = "Optional private endpoint configuration for the Key Vault. When set, creates an azurerm_private_endpoint in the given subnet and a private DNS zone linked to the given VNet. Set to null to skip private endpoint creation."
  default     = null
  nullable    = true
}

variable "network_acls" {
  type = object({
    default_action             = string
    bypass                     = string
    ip_rules                   = optional(set(string), [])
    virtual_network_subnet_ids = optional(set(string), [])
  })
  description = "Network ACL configuration for the Key Vault. default_action must be \"Allow\" or \"Deny\"; bypass must be \"AzureServices\" or \"None\" (use \"AzureServices\" for Databricks control-plane access). The default restricts public access; supply ip_rules or virtual_network_subnet_ids to allow specific sources."
  default = {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = []
  }
  nullable = false
  validation {
    condition     = contains(["Allow", "Deny"], var.network_acls.default_action)
    error_message = "network_acls.default_action must be \"Allow\" or \"Deny\"."
  }
  validation {
    condition     = contains(["AzureServices", "None"], var.network_acls.bypass)
    error_message = "network_acls.bypass must be \"AzureServices\" (required for Databricks control-plane access) or \"None\"."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources created by this module (Key Vault, keys, private endpoint)."
  default     = {}
}

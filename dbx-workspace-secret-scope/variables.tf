variable "scopes" {
  type = map(object({
    initial_manage_principal = optional(string, null)
    keyvault_metadata = optional(object({
      resource_id = string
      dns_name    = string
    }), null)
  }))
  description = "Map of secret scope name to configuration. Each key is the scope name (must be unique within the workspace, max 128 chars, alphanumeric/dash/underscore/period). Set initial_manage_principal to \"users\" to grant all workspace users MANAGE on the scope; omit to grant only the calling principal. Provide keyvault_metadata only for Azure Key Vault-backed scopes — resource_id is the Azure KV resource ID and dns_name is the vault URI."
  nullable    = false

  validation {
    condition = alltrue([
      for name, _ in var.scopes :
      length(name) >= 1 && length(name) <= 128 && can(regex("^[A-Za-z0-9_.\\-]+$", name))
    ])
    error_message = "Each scope name must be 1-128 characters and contain only alphanumeric characters, dashes, underscores, and periods."
  }

  validation {
    condition = alltrue([
      for _, cfg in var.scopes :
      cfg.initial_manage_principal == null || cfg.initial_manage_principal == "users"
    ])
    error_message = "initial_manage_principal accepts only null or \"users\"."
  }
}

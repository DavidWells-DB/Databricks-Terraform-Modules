variable "workspace_id" {
  type        = number
  description = "Databricks workspace ID to bind the network policy to. A workspace has exactly one network option; binding a different policy overwrites the previous assignment."
  nullable    = false
}

variable "network_policy_id" {
  type        = string
  description = "Account network policy ID to assign to the workspace via databricks_workspace_network_option. This is the ID of a databricks_account_network_policy (see the dbx-account-network-policy module). Pass \"default-policy\" to assign the account default policy."
  nullable    = false
  validation {
    condition     = length(var.network_policy_id) >= 1
    error_message = "network_policy_id must be a non-empty account network policy ID (or \"default-policy\")."
  }
}

variable "unbind_settle_duration" {
  type        = string
  description = "How long to wait, on destroy, between unbinding the network policy from the workspace and allowing a dependent policy to be deleted. Fixes a delete-ordering race (open-item E12) where the policy delete fired before the unbind had propagated. Accepts Go duration syntax (e.g. \"30s\", \"1m\"). Applied on destroy only — no create delay."
  default     = "30s"
  nullable    = false
  validation {
    condition     = can(regex("^[0-9]+(s|m|h)$", var.unbind_settle_duration))
    error_message = "unbind_settle_duration must be a Go duration like \"30s\", \"1m\", or \"1h\"."
  }
}

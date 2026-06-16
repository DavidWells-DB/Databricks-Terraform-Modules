variable "workspace_id" {
  type        = number
  description = "Databricks workspace ID to bind to the NCC. A workspace can be bound to only one NCC at a time; binding a different NCC overwrites the previous binding."
  nullable    = false
}

variable "network_connectivity_config_id" {
  type        = string
  description = "Canonical unique identifier of the Network Connectivity Config (NCC) in the Databricks account. The NCC and workspace must be in the same region."
  nullable    = false
  validation {
    # NCC IDs are UUIDs. Validate format to catch copy-paste errors early.
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.network_connectivity_config_id))
    error_message = "network_connectivity_config_id must be a valid UUID (8-4-4-4-12 hex)."
  }
}

variable "private_endpoint_rules" {
  type = list(object({
    # Human-readable key used as the for_each map key; must be unique within the list.
    key = string

    # --- Azure fields ---
    # Azure resource ID of the target resource (e.g. storage account). Required for Azure PE rules.
    resource_id = optional(string)
    # Sub-resource type on Azure: "blob", "dfs", "sqlServer", etc.
    # Mutually exclusive with domain_names on Azure.
    group_id = optional(string)

    # --- AWS fields ---
    # Full AWS VPC endpoint service name (e.g. "com.amazonaws.us-east-1.s3").
    endpoint_service = optional(string)
    # S3 bucket names accessible via the VPC endpoint. Mutually exclusive with domain_names on AWS.
    resource_names = optional(list(string))
    # Activation status for AWS S3 service endpoints. Defaults to true.
    enabled = optional(bool, true)

    # --- Shared (Azure domain-based / AWS FQDN) ---
    # On Azure: domain names for private link service.
    # On AWS: FQDNs accessible via VPC endpoint.
    # On Azure, mutually exclusive with group_id. On AWS, mutually exclusive with resource_names.
    domain_names = optional(list(string))
  }))
  description = "List of private endpoint rules to create on the NCC. Each element maps to one databricks_mws_ncc_private_endpoint_rule. The key field must be unique and is used as the Terraform map key. Omit fields that are not applicable to the target cloud."
  default     = []
  nullable    = false
  validation {
    condition     = length(var.private_endpoint_rules) == length(toset([for r in var.private_endpoint_rules : r.key]))
    error_message = "Each private_endpoint_rules entry must have a unique key."
  }
}

variable "network_policy_id" {
  type        = string
  description = "Network policy ID to assign to the workspace via databricks_workspace_network_option. Controls network access for all serverless compute in the workspace. If null, the workspace_network_option resource is not created and the workspace retains its existing policy (or the Databricks default). Pass \"default-policy\" to explicitly assign the account default."
  default     = null
  nullable    = true
}

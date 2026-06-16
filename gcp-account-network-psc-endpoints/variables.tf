variable "databricks_account_id" {
  type        = string
  description = "Databricks account ID. Used to register PSC endpoints via the account API."
  nullable    = false
}

variable "project_id" {
  type        = string
  description = "Google Cloud project ID in which the PSC compute addresses and forwarding rules are created."
  nullable    = false
}

variable "region" {
  type        = string
  description = "GCP region for PSC endpoints. Must match the region of the Databricks workspace VPC. Supported regions: asia-northeast1, asia-south1, asia-southeast1, australia-southeast1, europe-west1, europe-west2, europe-west3, me-central2, northamerica-northeast1, southamerica-east1, us-central1, us-east1, us-east4, us-west1, us-west4."
  nullable    = false
  validation {
    condition = contains([
      "asia-northeast1",
      "asia-south1",
      "asia-southeast1",
      "australia-southeast1",
      "europe-west1",
      "europe-west2",
      "europe-west3",
      "me-central2",
      "northamerica-northeast1",
      "southamerica-east1",
      "us-central1",
      "us-east1",
      "us-east4",
      "us-west1",
      "us-west4",
    ], var.region)
    error_message = "region must be one of the 15 GCP regions supported by Databricks PSC. See https://docs.databricks.com/gcp/en/resources/ip-domain-region#psc for the full list."
  }
}

variable "network_self_link" {
  type        = string
  description = "Self-link of the GCP VPC network in which the PSC forwarding rules are created. Example: projects/my-project/global/networks/my-vpc."
  nullable    = false
}

variable "psc_subnet_self_link" {
  type        = string
  description = "Self-link of the subnet used for PSC endpoint IP address allocation. The subnet must be in the same region as var.region. Example: projects/my-project/regions/us-central1/subnetworks/my-psc-subnet."
  nullable    = false
}

variable "resource_prefix" {
  type        = string
  description = "Prefix applied to all GCP and Databricks resource names created by this module. Keep short (under 20 characters) to stay within GCP's 63-character name limits."
  nullable    = false
  validation {
    # GCP resource names: 1-63 chars, lowercase letters, digits, hyphens; must start with a letter.
    # We apply a conservative 20-char cap on the prefix so that generated names stay well under 63 chars.
    condition     = length(var.resource_prefix) >= 1 && length(var.resource_prefix) <= 20 && can(regex("^[a-z][a-z0-9-]*$", var.resource_prefix))
    error_message = "resource_prefix must be 1-20 characters, start with a lowercase letter, and contain only lowercase letters, digits, and hyphens."
  }
}

variable "workspace_psc_service_attachment" {
  type        = string
  description = "Optional override for the Databricks workspace PSC service attachment URI. When null the module computes the correct URI from var.region using the documented Databricks PSC attachment map. Override only if Databricks has published an updated URI for your region."
  default     = null
}

variable "relay_psc_service_attachment" {
  type        = string
  description = "Optional override for the Databricks SCC relay PSC service attachment URI. When null the module computes the correct URI from var.region using the documented Databricks PSC attachment map. Override only if Databricks has published an updated URI for your region."
  default     = null
}

variable "public_access_enabled" {
  type        = bool
  description = "Whether public internet access to Databricks workspaces associated with this Private Access Settings object is allowed. Set to false to enforce private-only access."
  default     = true
  nullable    = false
}

variable "private_access_level" {
  type        = string
  description = "The level of access allowed for the private access settings. ACCOUNT allows all VPC endpoints in the account; ENDPOINT restricts to var.allowed_vpc_endpoint_ids."
  default     = "ACCOUNT"
  nullable    = false
  validation {
    condition     = contains(["ACCOUNT", "ENDPOINT"], var.private_access_level)
    error_message = "private_access_level must be \"ACCOUNT\" or \"ENDPOINT\"."
  }
}

variable "allowed_vpc_endpoint_ids" {
  type        = list(string)
  description = "List of Databricks VPC endpoint IDs allowed to connect when private_access_level is ENDPOINT. Ignored when private_access_level is ACCOUNT."
  default     = []
  nullable    = false
}

variable "private_access_settings_name" {
  type        = string
  description = "Descriptive name for the Databricks Private Access Settings object. Defaults to <resource_prefix>-pas when null."
  default     = null
}

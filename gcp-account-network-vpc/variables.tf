variable "project_id" {
  type        = string
  description = "GCP project ID in which the VPC, subnetwork, and firewall rules are created."
  nullable    = false
  validation {
    # GCP project IDs: 6-30 chars, lowercase letters, digits, hyphens, must start with a letter.
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be 6-30 characters, start with a lowercase letter, and contain only lowercase letters, digits, and hyphens."
  }
}

variable "region" {
  type        = string
  description = "GCP region for the subnetwork and Databricks workspace data plane (e.g. \"us-central1\"). Must match the region used by the Databricks workspace."
  nullable    = false
  validation {
    # GCP region names follow the pattern: <geography>-<direction><number> (e.g. us-central1, europe-west4).
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]+$", var.region))
    error_message = "region must be a valid GCP region name (e.g. \"us-central1\", \"europe-west4\")."
  }
}

variable "resource_prefix" {
  type        = string
  description = "Prefix applied to the VPC, subnetwork, and firewall resource names. Must be 1-20 characters, lowercase letters, digits, or hyphens, starting with a letter."
  nullable    = false
  validation {
    # GCP resource names: lowercase alphanumeric and hyphens, must start with a letter.
    # Constrained to 20 chars so final resource names stay well within GCP's 63-char limit.
    condition     = can(regex("^[a-z][a-z0-9-]{0,18}[a-z0-9]$", var.resource_prefix)) || can(regex("^[a-z]$", var.resource_prefix))
    error_message = "resource_prefix must be 1-20 characters, start with a lowercase letter, and contain only lowercase letters, digits, and hyphens."
  }
}

variable "databricks_account_id" {
  type        = string
  description = "Databricks account ID. Used to register the network configuration with the Databricks account API."
  nullable    = false
  validation {
    # Databricks account IDs are UUIDs.
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.databricks_account_id))
    error_message = "databricks_account_id must be a valid UUID (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)."
  }
}

variable "network_name" {
  type        = string
  description = "Name for the databricks_mws_networks registration. Should be descriptive and unique within the Databricks account."
  nullable    = false
  validation {
    # No public Databricks-documented constraint; using conservative common-sense bounds.
    # 1-100 chars, alphanumeric + hyphen + underscore. Tighten if Databricks publishes constraints.
    condition     = length(var.network_name) >= 1 && length(var.network_name) <= 100 && can(regex("^[A-Za-z0-9_-]+$", var.network_name))
    error_message = "network_name must be 1-100 characters and contain only alphanumeric, underscore, or hyphen."
  }
}

variable "network_cidr" {
  type        = string
  description = "Primary CIDR block for the VPC subnetwork. Databricks requires a subnet between /9 and /29 (e.g. \"10.0.0.0/16\")."
  nullable    = false
  validation {
    condition     = can(cidrhost(var.network_cidr, 0))
    error_message = "network_cidr must be a valid IPv4 CIDR block (e.g. \"10.0.0.0/16\")."
  }
  validation {
    # Databricks requires subnet netmask between /9 and /29.
    # The can() guard prevents an index-out-of-bounds error when the input has no "/" separator;
    # that case is already caught by the cidrhost() validation above.
    condition     = can(tonumber(split("/", var.network_cidr)[1])) && tonumber(split("/", var.network_cidr)[1]) >= 9 && tonumber(split("/", var.network_cidr)[1]) <= 29
    error_message = "network_cidr prefix length must be between /9 and /29 per Databricks GCP requirements."
  }
}

variable "pod_secondary_range_cidr" {
  type        = string
  description = "CIDR for the secondary IP range used by GKE pods. Required by Databricks GCP workspaces for cluster pod networking (e.g. \"10.1.0.0/16\")."
  nullable    = false
  validation {
    condition     = can(cidrhost(var.pod_secondary_range_cidr, 0))
    error_message = "pod_secondary_range_cidr must be a valid IPv4 CIDR block."
  }
}

variable "service_secondary_range_cidr" {
  type        = string
  description = "CIDR for the secondary IP range used by GKE services. Required by Databricks GCP workspaces for cluster service networking (e.g. \"10.2.0.0/20\")."
  nullable    = false
  validation {
    condition     = can(cidrhost(var.service_secondary_range_cidr, 0))
    error_message = "service_secondary_range_cidr must be a valid IPv4 CIDR block."
  }
}

variable "vpc_endpoint_ids" {
  type = object({
    dataplane_relay = optional(list(string))
    rest_api        = optional(list(string))
  })
  description = "Optional PSC (Private Service Connect) endpoint IDs from gcp-account-network-psc-endpoints. When provided, wired into the databricks_mws_networks registration to enable PSC connectivity. Set to null to skip PSC wiring."
  default     = null
}

variable "project_id" {
  type        = string
  description = "GCP project ID in which the Cloud Router and Cloud NAT will be created."
  nullable    = false
}

variable "region" {
  type        = string
  description = "GCP region for the Cloud Router and Cloud NAT (e.g. \"us-central1\"). Must match the region of the subnets that need egress."
  nullable    = false
}

variable "network_self_link" {
  type        = string
  description = "Self-link URI of the VPC network to attach the Cloud Router to (format: https://www.googleapis.com/compute/v1/projects/<project>/global/networks/<name>)."
  nullable    = false
  validation {
    condition     = can(regex("^https://www\\.googleapis\\.com/compute/v1/projects/[^/]+/global/networks/[^/]+$", var.network_self_link))
    error_message = "network_self_link must be a fully-qualified Compute API network self-link: https://www.googleapis.com/compute/v1/projects/<project>/global/networks/<name>."
  }
}

variable "subnetwork_self_link" {
  type        = string
  description = "Self-link URI of the subnetwork whose primary and secondary IP ranges should be NAT-translated. The Cloud NAT is configured to cover this subnetwork only (LIST_OF_SUBNETWORKS mode)."
  nullable    = false
  validation {
    condition     = can(regex("^https://www\\.googleapis\\.com/compute/v1/projects/[^/]+/regions/[^/]+/subnetworks/[^/]+$", var.subnetwork_self_link))
    error_message = "subnetwork_self_link must be a fully-qualified Compute API subnetwork self-link: https://www.googleapis.com/compute/v1/projects/<project>/regions/<region>/subnetworks/<name>."
  }
}

variable "resource_prefix" {
  type        = string
  description = "Prefix applied to the Cloud Router name and Cloud NAT name. Must be 1-50 characters; lowercase letters, digits, and hyphens only; must start with a letter."
  nullable    = false
  validation {
    # GCP resource names: 1-63 chars, must start with a lowercase letter, contain only lowercase
    # letters, digits, hyphens, must not end with a hyphen. We enforce a 50-char prefix cap so the
    # module-appended suffixes (-router, -nat) stay within the 63-char limit.
    condition     = length(var.resource_prefix) >= 1 && length(var.resource_prefix) <= 50 && can(regex("^[a-z][a-z0-9-]*[a-z0-9]$|^[a-z]$", var.resource_prefix))
    error_message = "resource_prefix must be 1-50 characters, start with a lowercase letter, contain only lowercase letters, digits, and hyphens, and must not end with a hyphen."
  }
}

variable "min_ports_per_vm" {
  type        = number
  description = "Minimum number of ports allocated per VM instance for NAT. Higher values reduce port exhaustion risk for workloads with many outbound connections. Defaults to 64."
  default     = 64
  nullable    = false
  validation {
    # GCP Cloud NAT accepts values that are powers of 2 in the range [64, 65536].
    condition     = contains([64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536], var.min_ports_per_vm)
    error_message = "min_ports_per_vm must be a power of 2 between 64 and 65536 (64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, or 65536)."
  }
}

variable "log_config_enable" {
  type        = bool
  description = "Whether to enable Cloud NAT logging. When true, NAT translations are logged to Cloud Logging. Useful for network troubleshooting and audit. Defaults to false."
  default     = false
  nullable    = false
}

variable "log_config_filter" {
  type        = string
  description = "Specifies what NAT events to log. Valid values: \"ALL\" (all NAT events), \"ERRORS_ONLY\" (only errors), \"TRANSLATIONS_ONLY\" (only successful translations). Only used when log_config_enable is true."
  default     = "ERRORS_ONLY"
  nullable    = false
  validation {
    condition     = contains(["ALL", "ERRORS_ONLY", "TRANSLATIONS_ONLY"], var.log_config_filter)
    error_message = "log_config_filter must be one of: \"ALL\", \"ERRORS_ONLY\", or \"TRANSLATIONS_ONLY\"."
  }
}

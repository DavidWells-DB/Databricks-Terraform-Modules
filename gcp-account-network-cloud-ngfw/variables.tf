variable "organization_id" {
  type        = string
  description = "GCP organization ID. Used as the parent for the security profile, security profile group, and firewall endpoint. Format: numeric organization ID (e.g. \"123456789\")."
  nullable    = false
  validation {
    # GCP org IDs are numeric strings, 1-20 digits.
    condition     = can(regex("^[0-9]{1,20}$", var.organization_id))
    error_message = "organization_id must be a numeric string (e.g. \"123456789\")."
  }
}

variable "project_id" {
  type        = string
  description = "GCP project ID. Used as the billing project for firewall endpoint charges and as the parent for the firewall endpoint association."
  nullable    = false
  validation {
    # GCP project IDs: 6-30 chars, lowercase letters, digits, hyphens; must start with letter.
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be a valid GCP project ID: 6-30 lowercase alphanumeric characters and hyphens, starting with a letter."
  }
}

variable "zone" {
  type        = string
  description = "GCP zone for the firewall endpoint and firewall endpoint association. Cloud NGFW firewall endpoints are zonal resources. Example: \"us-central1-a\"."
  nullable    = false
  validation {
    # GCP zone format: <region>-<zone-letter>, e.g. us-central1-a
    condition     = can(regex("^[a-z]+-[a-z0-9]+-[a-z]$", var.zone))
    error_message = "zone must be a valid GCP zone name (e.g. \"us-central1-a\")."
  }
}

variable "network_self_link" {
  type        = string
  description = "Self-link of the VPC network to associate with the firewall endpoint. Format: \"https://www.googleapis.com/compute/v1/projects/{project}/global/networks/{network}\"."
  nullable    = false
  validation {
    condition     = can(regex("^https://www\\.googleapis\\.com/compute/v1/projects/[^/]+/global/networks/[^/]+$", var.network_self_link))
    error_message = "network_self_link must be a fully-qualified GCP compute network self-link (https://www.googleapis.com/compute/v1/projects/.../global/networks/...)."
  }
}

variable "resource_prefix" {
  type        = string
  description = "Prefix applied to all resource names created by this module (security profile, security profile group, firewall endpoint, association). Must be 1-30 characters, lowercase alphanumeric and hyphens."
  nullable    = false
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,28}[a-z0-9]$", var.resource_prefix)) || can(regex("^[a-z]$", var.resource_prefix))
    error_message = "resource_prefix must be 1-30 characters, start with a lowercase letter, and contain only lowercase letters, digits, and hyphens."
  }
}

variable "severity_overrides" {
  type = list(object({
    action   = string
    severity = string
  }))
  description = "List of threat-prevention severity overrides for the security profile. Each entry overrides the default action for a severity level. action must be one of ALERT, ALLOW, DEFAULT_ACTION, DENY. severity must be one of CRITICAL, HIGH, INFORMATIONAL, LOW, MEDIUM."
  default     = []
  validation {
    condition = alltrue([
      for o in var.severity_overrides :
      contains(["ALERT", "ALLOW", "DEFAULT_ACTION", "DENY"], o.action) &&
      contains(["CRITICAL", "HIGH", "INFORMATIONAL", "LOW", "MEDIUM"], o.severity)
    ])
    error_message = "Each severity_override must have action in [ALERT, ALLOW, DEFAULT_ACTION, DENY] and severity in [CRITICAL, HIGH, INFORMATIONAL, LOW, MEDIUM]."
  }
}

variable "threat_overrides" {
  type = list(object({
    action    = string
    threat_id = string
  }))
  description = "List of threat-prevention threat-ID overrides for the security profile. action must be one of ALERT, ALLOW, DEFAULT_ACTION, DENY."
  default     = []
  validation {
    condition = alltrue([
      for o in var.threat_overrides :
      contains(["ALERT", "ALLOW", "DEFAULT_ACTION", "DENY"], o.action)
    ])
    error_message = "Each threat_override must have action in [ALERT, ALLOW, DEFAULT_ACTION, DENY]."
  }
}

variable "labels" {
  type        = map(string)
  description = "Labels applied to all resources created by this module."
  default     = {}
}

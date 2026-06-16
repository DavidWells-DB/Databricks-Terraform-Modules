terraform {
  required_version = ">= 1.7.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "cloud_ngfw" {
  source = "../.."

  organization_id   = var.organization_id
  project_id        = var.project_id
  zone              = var.zone
  network_self_link = var.network_self_link
  resource_prefix   = "databricks-ngfw"

  severity_overrides = [
    {
      action   = "ALERT"
      severity = "INFORMATIONAL"
    },
    {
      action   = "DENY"
      severity = "CRITICAL"
    },
  ]

  labels = {
    module  = "gcp-account-network-cloud-ngfw"
    example = "basic"
  }
}

variable "organization_id" {
  type        = string
  description = "GCP organization ID (numeric)."
}

variable "project_id" {
  type        = string
  description = "GCP project ID for billing and the firewall endpoint association."
}

variable "region" {
  type        = string
  description = "GCP region for the google provider."
  default     = "us-central1"
}

variable "zone" {
  type        = string
  description = "GCP zone for the firewall endpoint and association. Must be in the same region as the VPC workloads."
  default     = "us-central1-a"
}

variable "network_self_link" {
  type        = string
  description = "Self-link of the VPC network to associate with the firewall endpoint."
}

output "security_profile_group_id" {
  description = "Security profile group ID — reference in network firewall policy rules."
  value       = module.cloud_ngfw.security_profile_group_id
}

output "firewall_endpoint_id" {
  description = "Cloud NGFW firewall endpoint ID."
  value       = module.cloud_ngfw.firewall_endpoint_id
}

output "firewall_endpoint_association_id" {
  description = "Firewall endpoint association ID."
  value       = module.cloud_ngfw.firewall_endpoint_association_id
}

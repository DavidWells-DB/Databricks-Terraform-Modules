terraform {
  required_version = ">= 1.7.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

provider "google" {
  project = var.gcp_project
}

module "vpc_service_controls" {
  source = "../.."

  access_policy_id          = var.access_policy_id
  perimeter_name            = "example_perimeter"
  perimeter_title           = "Example VPC Service Controls Perimeter"
  protected_project_numbers = var.protected_project_numbers
  restricted_services       = ["storage.googleapis.com", "bigquery.googleapis.com"]
}

variable "gcp_project" {
  type        = string
  description = "GCP project ID for the provider."
}

variable "access_policy_id" {
  type        = string
  description = "Access Context Manager access policy ID. Can be the policy ID or full resource name."
}

variable "protected_project_numbers" {
  type        = list(string)
  description = "List of GCP project numbers to protect with the perimeter."
}

output "perimeter_id" {
  value = module.vpc_service_controls.perimeter_id
}

output "protected_projects" {
  value = module.vpc_service_controls.protected_projects
}

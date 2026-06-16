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
  project = var.project_id
  region  = var.region
}

module "cloud_nat" {
  source = "../.."

  project_id           = var.project_id
  region               = var.region
  network_self_link    = var.network_self_link
  subnetwork_self_link = var.subnetwork_self_link
  resource_prefix      = var.resource_prefix
}

variable "project_id" {
  type        = string
  description = "GCP project ID."
}

variable "region" {
  type        = string
  description = "GCP region (e.g. \"us-central1\")."
  default     = "us-central1"
}

variable "network_self_link" {
  type        = string
  description = "Self-link URI of the VPC network (https://www.googleapis.com/compute/v1/projects/<project>/global/networks/<name>)."
}

variable "subnetwork_self_link" {
  type        = string
  description = "Self-link URI of the subnetwork to NAT (https://www.googleapis.com/compute/v1/projects/<project>/regions/<region>/subnetworks/<name>)."
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for Cloud Router and Cloud NAT resource names."
  default     = "databricks"
}

output "router_id" {
  value = module.cloud_nat.router_id
}

output "nat_id" {
  value = module.cloud_nat.nat_id
}

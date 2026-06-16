# VPC — custom mode so subnetwork CIDRs are fully under caller control.
resource "google_compute_network" "this" {
  project                 = var.project_id
  name                    = "${var.resource_prefix}-vpc"
  auto_create_subnetworks = false
  description             = "Databricks workspace VPC (${var.resource_prefix})"
}

# Subnetwork with two secondary IP ranges required by Databricks GCP workspaces:
#   - pods:     GKE pod networking
#   - services: GKE service networking
# private_ip_google_access enables VMs to reach Google APIs without public IPs.
resource "google_compute_subnetwork" "this" { #tfsec:ignore:google-compute-enable-vpc-flow-logs
  project                  = var.project_id
  name                     = local.subnetwork_name
  region                   = var.region
  network                  = google_compute_network.this.id
  ip_cidr_range            = var.network_cidr
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = local.pod_secondary_range_name
    ip_cidr_range = var.pod_secondary_range_cidr
  }

  secondary_ip_range {
    range_name    = local.service_secondary_range_name
    ip_cidr_range = var.service_secondary_range_cidr
  }

  #checkov:skip=CKV_GCP_26: VPC flow log delivery is an operational concern managed by a separate module.
}

# Databricks-required ingress firewall rule: allows all intra-subnet traffic so
# cluster driver and worker nodes can communicate with each other.
# Source: https://docs.databricks.com/gcp/en/administration-guide/cloud-configurations/gcp/customer-managed-vpc.html
resource "google_compute_firewall" "this" {
  project     = var.project_id
  name        = "db-${local.subnetwork_name}-ingress"
  network     = google_compute_network.this.id
  description = "Databricks-required ingress: allow all intra-subnet traffic for cluster node communication."
  direction   = "INGRESS"
  priority    = 1000

  allow {
    protocol = "all"
  }

  source_ranges = [var.network_cidr]
}

# Register the GCP VPC configuration with the Databricks account API.
# Pairs the cloud-side VPC with its Databricks-side registration per DATABRICKS_RULES.md Rule 1.4.
resource "databricks_mws_networks" "this" {
  provider     = databricks.account
  account_id   = var.databricks_account_id
  network_name = var.network_name

  gcp_network_info {
    network_project_id = var.project_id
    vpc_id             = google_compute_network.this.name
    subnet_id          = google_compute_subnetwork.this.name
    subnet_region      = google_compute_subnetwork.this.region
  }

  dynamic "vpc_endpoints" {
    # Only include the vpc_endpoints block when PSC endpoint IDs are provided.
    for_each = local.has_vpc_endpoints ? [var.vpc_endpoint_ids] : []

    content {
      dataplane_relay = coalesce(vpc_endpoints.value.dataplane_relay, [])
      rest_api        = coalesce(vpc_endpoints.value.rest_api, [])
    }
  }
}

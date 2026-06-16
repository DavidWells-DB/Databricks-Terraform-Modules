output "network_self_link" {
  description = "Self-link of the created VPC. Pass to downstream modules (e.g., gcp-account-network-cloud-nat, gcp-account-network-psc-endpoints) as their network_self_link input."
  value       = google_compute_network.this.self_link
}

output "network_name" {
  description = "Name of the created VPC network. Useful for firewall rules or Shared VPC host configurations."
  value       = google_compute_network.this.name
}

output "subnetwork_self_link" {
  description = "Self-link of the created subnetwork. Pass to downstream modules (e.g., gcp-account-network-psc-endpoints) as their subnetwork_self_link input."
  value       = google_compute_subnetwork.this.self_link
}

output "subnetwork_name" {
  description = "Name of the created subnetwork."
  value       = google_compute_subnetwork.this.name
}

output "databricks_network_id" {
  description = "Databricks network configuration ID from databricks_mws_networks. Pass to workspace creation modules as their network_id input."
  value       = databricks_mws_networks.this.network_id
}

output "pod_secondary_range_name" {
  description = "Name of the secondary IP range reserved for GKE pods. Required when configuring GKE node pools or PSC subnets that reference this range."
  value       = local.pod_secondary_range_name
}

output "service_secondary_range_name" {
  description = "Name of the secondary IP range reserved for GKE services. Required when configuring GKE node pools or PSC subnets that reference this range."
  value       = local.service_secondary_range_name
}

output "network_cidr" {
  description = "Primary CIDR block of the subnetwork. Useful for constructing downstream firewall rules that reference the workspace subnet range."
  value       = google_compute_subnetwork.this.ip_cidr_range
}

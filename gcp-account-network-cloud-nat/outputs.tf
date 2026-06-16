output "router_id" {
  description = "Fully-qualified resource ID of the Cloud Router (projects/<project>/regions/<region>/routers/<name>). Useful for referencing the router in other GCP resources such as BGP or VPN attachments."
  value       = google_compute_router.this.id
}

output "router_name" {
  description = "Name of the Cloud Router. Can be used to reference the router in additional google_compute_router_nat or BGP peer configurations."
  value       = google_compute_router.this.name
}

output "router_self_link" {
  description = "Self-link URI of the Cloud Router."
  value       = google_compute_router.this.self_link
}

output "nat_id" {
  description = "Fully-qualified resource ID of the Cloud NAT (projects/<project>/regions/<region>/routers/<router>/nats/<name>). Useful for referencing the NAT configuration in monitoring or policy resources."
  value       = google_compute_router_nat.this.id
}

output "nat_name" {
  description = "Name of the Cloud NAT resource."
  value       = google_compute_router_nat.this.name
}

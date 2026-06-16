output "workspace_psc_endpoint_id" {
  description = "Databricks VPC endpoint ID for the workspace PSC forwarding rule. Pass to workspace creation modules as part of the private access configuration."
  value       = databricks_mws_vpc_endpoint.workspace.vpc_endpoint_id
}

output "relay_psc_endpoint_id" {
  description = "Databricks VPC endpoint ID for the SCC relay PSC forwarding rule."
  value       = databricks_mws_vpc_endpoint.relay.vpc_endpoint_id
}

output "private_access_settings_id" {
  description = "Databricks Private Access Settings ID. Pass to workspace creation modules as private_access_settings_id."
  value       = databricks_mws_private_access_settings.this.private_access_settings_id
}

output "workspace_psc_ip" {
  description = "Internal IP address allocated for the workspace PSC forwarding rule. Useful for verifying DNS resolution."
  value       = google_compute_address.workspace.address
}

output "relay_psc_ip" {
  description = "Internal IP address allocated for the SCC relay PSC forwarding rule."
  value       = google_compute_address.relay.address
}

output "workspace_psc_forwarding_rule_id" {
  description = "GCP self-link of the workspace PSC forwarding rule resource."
  value       = google_compute_forwarding_rule.workspace.self_link
}

output "relay_psc_forwarding_rule_id" {
  description = "GCP self-link of the SCC relay PSC forwarding rule resource."
  value       = google_compute_forwarding_rule.relay.self_link
}

output "dns_zone_name" {
  description = "GCP name of the private DNS managed zone created for gcp.databricks.com."
  value       = google_dns_managed_zone.databricks.name
}

output "workspace_psc_service_attachment" {
  description = "Effective workspace PSC service attachment URI used for the forwarding rule. Reflects the computed-or-overridden value. Useful for audit and debugging."
  value       = local.workspace_psc_attachment
}

output "relay_psc_service_attachment" {
  description = "Effective SCC relay PSC service attachment URI used for the forwarding rule. Reflects the computed-or-overridden value. Useful for audit and debugging."
  value       = local.relay_psc_attachment
}

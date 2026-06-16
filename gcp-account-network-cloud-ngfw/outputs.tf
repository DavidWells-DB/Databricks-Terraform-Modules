output "security_profile_id" {
  description = "Fully-qualified resource ID of the Cloud NGFW security profile. Format: organizations/{org}/locations/global/securityProfiles/{name}."
  value       = google_network_security_security_profile.this.id
}

output "security_profile_name" {
  description = "Display name of the Cloud NGFW security profile resource."
  value       = google_network_security_security_profile.this.name
}

output "security_profile_group_id" {
  description = "Fully-qualified resource ID of the Cloud NGFW security profile group. Reference this in network firewall policy rules via the security_profile_group field."
  value       = google_network_security_security_profile_group.this.id
}

output "security_profile_group_name" {
  description = "Display name of the Cloud NGFW security profile group resource."
  value       = google_network_security_security_profile_group.this.name
}

output "firewall_endpoint_id" {
  description = "Fully-qualified resource ID of the Cloud NGFW firewall endpoint. Format: organizations/{org}/locations/{zone}/firewallEndpoints/{name}."
  value       = google_network_security_firewall_endpoint.this.id
}

output "firewall_endpoint_self_link" {
  description = "Server-defined URL of the Cloud NGFW firewall endpoint. Useful for cross-referencing in firewall policy rules."
  value       = google_network_security_firewall_endpoint.this.self_link
}

output "firewall_endpoint_state" {
  description = "Current state of the Cloud NGFW firewall endpoint (e.g. ACTIVE). Used to verify the endpoint is ready before associating firewall policy rules."
  value       = google_network_security_firewall_endpoint.this.state
}

output "firewall_endpoint_association_id" {
  description = "Fully-qualified resource ID of the firewall endpoint association. Format: projects/{project}/locations/{zone}/firewallEndpointAssociations/{name}."
  value       = google_network_security_firewall_endpoint_association.this.id
}

output "firewall_endpoint_association_state" {
  description = "Current state of the firewall endpoint association. Traffic steering is only active when this is ACTIVE."
  value       = google_network_security_firewall_endpoint_association.this.state
}

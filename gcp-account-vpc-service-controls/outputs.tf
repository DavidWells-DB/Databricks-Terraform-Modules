output "perimeter_id" {
  description = "Full resource name of the VPC Service Controls perimeter."
  value       = google_access_context_manager_service_perimeter.this.id
}

output "perimeter_name" {
  description = "Name of the service perimeter."
  value       = var.perimeter_name
}

output "restricted_services" {
  description = "List of GCP services restricted by the perimeter."
  value       = google_access_context_manager_service_perimeter.this.status[0].restricted_services
}

output "protected_projects" {
  description = "List of GCP project numbers protected by the perimeter."
  value       = local.normalized_projects
}

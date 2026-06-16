output "host_project_id" {
  description = "GCP project ID of the Shared VPC host project. Pass to workspace or network modules that require the host project reference."
  value       = google_compute_shared_vpc_host_project.this.project
}

output "service_project_ids" {
  description = "Set of GCP project IDs attached as Shared VPC service projects."
  value       = [for sp in google_compute_shared_vpc_service_project.this : sp.service_project]
}

output "service_project_attachment_ids" {
  description = "Map of service project ID to the Terraform resource ID of its Shared VPC attachment (format: host_project/service_project). Useful for referencing or importing attachments."
  value       = { for k, sp in google_compute_shared_vpc_service_project.this : k => sp.id }
}

output "subnet_iam_grant_ids" {
  description = "Map of subnet IAM grant key (subnetwork/region/member/role) to the Terraform resource ID of the google_compute_subnetwork_iam_member resource. Empty when no subnet_iam_grants are configured."
  value       = { for k, g in google_compute_subnetwork_iam_member.this : k => g.id }
}

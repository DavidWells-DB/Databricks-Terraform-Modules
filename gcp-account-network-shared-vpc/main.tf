# Enable the host project as a Shared VPC host.
# Only one host project resource is needed per host project.
resource "google_compute_shared_vpc_host_project" "this" {
  project = var.host_project_id
}

# Attach each service project to the Shared VPC host.
# for_each is used because each service project has an independent identity (its own project ID).
resource "google_compute_shared_vpc_service_project" "this" {
  for_each = toset(var.service_project_ids)

  host_project    = google_compute_shared_vpc_host_project.this.project
  service_project = each.key
}

# Grant subnet-level IAM roles in the host project to members from service projects.
# Keyed by a stable composite of subnetwork+region+member+role to support multiple grants
# on the same subnetwork without collision.
resource "google_compute_subnetwork_iam_member" "this" {
  for_each = {
    for grant in var.subnet_iam_grants :
    "${grant.subnetwork}/${grant.region}/${grant.member}/${grant.role}" => grant
  }

  project    = var.host_project_id
  region     = each.value.region
  subnetwork = each.value.subnetwork
  role       = each.value.role
  member     = each.value.member
}

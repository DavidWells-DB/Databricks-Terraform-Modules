locals {
  # Parent resource path for org-scoped resources (security profiles, profile group, firewall endpoint).
  org_parent = "organizations/${var.organization_id}"

  # Parent resource path for project-scoped resources (firewall endpoint association).
  project_parent = "projects/${var.project_id}"
}

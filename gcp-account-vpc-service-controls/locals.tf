locals {
  # Normalize access policy ID to full resource name format
  normalized_access_policy = startswith(var.access_policy_id, "accessPolicies/") ? var.access_policy_id : "accessPolicies/${var.access_policy_id}"

  # Normalize protected project numbers to "projects/<number>" format
  normalized_projects = [
    for p in var.protected_project_numbers :
    startswith(p, "projects/") ? p : "projects/${p}"
  ]
}

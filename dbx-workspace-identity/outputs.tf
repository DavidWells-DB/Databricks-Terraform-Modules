output "assignment_ids" {
  description = "Map of assignment label to the Databricks permission assignment ID. Keyed by the same keys as the assignments input variable."
  value = {
    for k, v in databricks_mws_permission_assignment.this : k => v.id
  }
}

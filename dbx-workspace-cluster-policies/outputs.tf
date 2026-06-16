output "policy_ids" {
  description = "Map of policy name to Databricks cluster policy ID. Pass individual IDs to compute resources that require a policy_id."
  value       = { for k, v in databricks_cluster_policy.this : k => v.id }
}

output "policy_policy_ids" {
  description = "Map of policy name to the Databricks-internal policy_id (distinct from the resource `id`). Required when referencing a policy in cluster definitions."
  value       = { for k, v in databricks_cluster_policy.this : k => v.policy_id }
}

output "policy_names" {
  description = "List of created cluster policy names, in the order returned by for_each iteration."
  value       = [for k, _ in databricks_cluster_policy.this : k]
}

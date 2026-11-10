output "binding_ids" {
  description = "Map of binding key to the binding resource ID."
  value       = { for k, b in databricks_workspace_binding.this : k => b.id }
}

output "workspace_ids" {
  description = "Map of binding key to the bound workspace_id (convenience for wiring exports)."
  value       = { for k, b in databricks_workspace_binding.this : k => b.workspace_id }
}

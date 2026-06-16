output "scope_names" {
  description = "Set of secret scope names created by this module. Useful for downstream modules or resources that reference these scopes by name."
  value       = toset([for name, _ in databricks_secret_scope.this : name])
}

output "scope_ids" {
  description = "Map of scope name to Databricks secret scope object ID. Useful for constructing ACL rules or debugging scope registration."
  value       = { for name, scope in databricks_secret_scope.this : name => scope.id }
}

output "scope_backend_types" {
  description = "Map of scope name to backend type (DATABRICKS or AZURE_KEYVAULT). Useful for verifying that Azure Key Vault-backed scopes were registered correctly."
  value       = { for name, scope in databricks_secret_scope.this : name => scope.backend_type }
}

output "schema_ids" {
  description = "Map of schema name to the Databricks schema ID (same as schema name in UC; exposed for downstream reference and test assertions)."
  value       = { for name, schema in databricks_schema.this : name => schema.id }
}

output "schema_names" {
  description = "Set of schema names created by this module. Useful for downstream modules that consume schema names as inputs."
  value       = toset([for name, _ in databricks_schema.this : name])
}

output "schema_storage_roots" {
  description = "Map of schema name to the storage root URI. Null for schemas using the catalog default."
  value       = { for name, schema in databricks_schema.this : name => schema.storage_root }
}

output "catalog_name" {
  description = "Name of the catalog in which schemas were created. Useful for constructing fully-qualified names downstream."
  value       = var.catalog_name
}

output "catalog_ids" {
  description = "Map of catalog name to the Databricks catalog ID (same as catalog name in UC; exposed for downstream reference and test assertions)."
  value       = { for name, cat in databricks_catalog.this : name => cat.id }
}

output "catalog_names" {
  description = "Set of catalog names created by this module. Useful for downstream modules that consume catalog names as inputs."
  value       = toset([for name, _ in databricks_catalog.this : name])
}

output "catalog_metastore_ids" {
  description = "Map of catalog name to the metastore ID the catalog belongs to. Useful for verification."
  value       = { for name, cat in databricks_catalog.this : name => cat.metastore_id }
}

output "catalog_storage_roots" {
  description = "Map of catalog name to the storage root URI. Null for catalogs using the metastore default."
  value       = { for name, cat in databricks_catalog.this : name => cat.storage_root }
}

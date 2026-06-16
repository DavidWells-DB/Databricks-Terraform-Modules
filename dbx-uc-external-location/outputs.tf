output "external_location_ids" {
  description = "Map of external location name to its Databricks resource ID. Useful for referencing locations in downstream resources."
  value       = { for name, loc in databricks_external_location.this : name => loc.id }
}

output "external_location_names" {
  description = "Map of external location name to its registered name in Unity Catalog. Matches the input map keys."
  value       = { for name, loc in databricks_external_location.this : name => loc.name }
}

output "external_location_urls" {
  description = "Map of external location name to its cloud storage URL. Useful for verification and downstream configuration."
  value       = { for name, loc in databricks_external_location.this : name => loc.url }
}

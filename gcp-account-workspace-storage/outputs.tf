output "storage_configuration_id" {
  description = "Databricks storage configuration ID. Pass to workspace creation modules as the storage_configuration_id input."
  value       = databricks_mws_storage_configurations.this.storage_configuration_id
}

output "bucket_name" {
  description = "Name of the GCS bucket used as workspace root storage."
  value       = google_storage_bucket.this.name
}

output "bucket_url" {
  description = "GCS URL of the root storage bucket (gs://<bucket-name>)."
  value       = google_storage_bucket.this.url
}

output "bucket_self_link" {
  description = "Self-link URI of the GCS bucket. Useful for referencing the bucket in other Google Cloud resources."
  value       = google_storage_bucket.this.self_link
}

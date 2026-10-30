output "bucket_name" {
  description = "Name of the dedicated UC bucket."
  value       = google_storage_bucket.this.name
}

output "storage_root" {
  description = "The Unity Catalog storage-root URL for this bucket (gs://<bucket>). Append the catalog's path suffix at the composition."
  value       = "gs://${google_storage_bucket.this.name}"
}

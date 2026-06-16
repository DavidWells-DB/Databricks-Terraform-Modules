# Databricks provisions a managed GCP service account when databricks_gcp_service_account {} is
# declared as an empty block. The service account email is not known until after apply; it is
# exposed via databricks_storage_credential.this.databricks_gcp_service_account[0].email.
resource "databricks_storage_credential" "this" {
  provider       = databricks.workspace
  name           = var.credential_name
  comment        = var.comment
  isolation_mode = var.isolation_mode

  databricks_gcp_service_account {}
}

# Grant the Databricks-managed service account object-level write access to the target bucket.
# roles/storage.objectAdmin allows CREATE, DELETE, GET, LIST on objects within the bucket.
resource "google_storage_bucket_iam_member" "object_admin" {
  bucket = var.bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${databricks_storage_credential.this.databricks_gcp_service_account[0].email}"
}

# Grant the Databricks-managed service account bucket metadata read access.
# roles/storage.legacyBucketReader is required for Unity Catalog to enumerate bucket contents.
resource "google_storage_bucket_iam_member" "bucket_reader" {
  bucket = var.bucket_name
  role   = "roles/storage.legacyBucketReader"
  member = "serviceAccount:${databricks_storage_credential.this.databricks_gcp_service_account[0].email}"
}

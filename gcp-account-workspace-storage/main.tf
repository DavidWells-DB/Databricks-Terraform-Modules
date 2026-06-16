# CMEK is optional and exposed via kms_key_name. Google-managed encryption is
# an accepted default for workspaces not requiring CMEK per their compliance posture.
resource "google_storage_bucket" "this" { #tfsec:ignore:google-storage-bucket-encryption-customer-key
  #checkov:skip=CKV_GCP_62:Access logging requires a separate logging bucket; this is a root-composition concern outside this module's scope.
  #checkov:skip=CKV_GCP_78:Versioning is intentionally disabled. Databricks manages workspace root storage object lifecycle internally; enabling versioning creates unnecessary overhead and cost.
  name                        = local.bucket_name
  location                    = var.region
  project                     = var.project_id
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy
  # Explicitly prevent public access; Databricks accesses this bucket via the
  # Databricks-managed service account only.
  public_access_prevention = "enforced"
  labels                   = var.labels

  dynamic "encryption" {
    for_each = var.kms_key_name != null ? [var.kms_key_name] : []
    content {
      default_kms_key_name = encryption.value
    }
  }
}

# Databricks requires roles/storage.objectAdmin on the bucket to read/write workspace data.
resource "google_storage_bucket_iam_member" "object_admin" {
  bucket = google_storage_bucket.this.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.databricks_service_account_email}"
}

# Databricks requires roles/storage.legacyBucketReader to list and read bucket metadata.
resource "google_storage_bucket_iam_member" "legacy_bucket_reader" {
  bucket = google_storage_bucket.this.name
  role   = "roles/storage.legacyBucketReader"
  member = "serviceAccount:${var.databricks_service_account_email}"
}

resource "databricks_mws_storage_configurations" "this" {
  provider                   = databricks.account
  account_id                 = var.databricks_account_id
  storage_configuration_name = "${var.resource_prefix}-storage"
  bucket_name                = google_storage_bucket.this.name
}

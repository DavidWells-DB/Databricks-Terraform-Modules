# A dedicated GCS bucket for a Unity Catalog catalog's MANAGED storage.
#
# BEST PRACTICE (recorded in the Blueprints OKF unity-catalog entry, 2026-10-30):
# a catalog's managed storage belongs on a DEDICATED bucket — not the workspace
# root bucket, which the platform's auto-created workspace catalog shares with
# internal workspace storage. This module is the CREATE side of create-vs-adopt
# (Rule 8.4); the adopt side is an existing bucket + path passed directly to the
# composition (the gcp-uc-storage-credential module already handles existing
# buckets by granting its Databricks-managed SA object access on them).
#
# Access flows through the storage credential's Databricks-managed service account
# (roles/storage.objectAdmin + legacyBucketReader, granted by the credential
# module) — never public. Uniform bucket-level access with public-access
# prevention is enforced here.

resource "google_storage_bucket" "this" {
  name          = var.bucket_name
  location      = var.location
  force_destroy = var.force_destroy

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  labels = var.labels
}

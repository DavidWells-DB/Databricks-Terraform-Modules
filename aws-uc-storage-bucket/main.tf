# A dedicated S3 bucket for a Unity Catalog catalog's MANAGED storage.
#
# BEST PRACTICE (recorded in the Blueprints OKF unity-catalog entry, 2026-10-30):
# a catalog's managed storage belongs on a DEDICATED bucket — not the workspace
# root bucket, which the platform's auto-created workspace catalog shares with
# DBFS root and internal workspace storage. This module is the CREATE side of
# create-vs-adopt (Rule 8.4); the adopt side is an existing bucket + path passed
# directly to the composition (the storage-credential module already handles
# existing buckets).
#
# Deliberately lean: no DBFS-root bucket policy (that is workspace-registration
# machinery, not needed here — access flows through the UC credential's IAM
# role), no versioning resource (UC managed storage has no versioning
# requirement; add one in the root composition if your org mandates it).

# tfsec:ignore:aws-s3-enable-bucket-logging
# Access logging is a root-composition concern (e.g. an aws_s3_bucket_logging
# resource pointing at a central log bucket); callers that require it wire it
# in their root configuration.
resource "aws_s3_bucket" "this" { #tfsec:ignore:aws-s3-enable-bucket-logging
  bucket        = var.bucket_name
  force_destroy = var.force_destroy
  tags          = var.tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_arn != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = var.kms_key_arn != null
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

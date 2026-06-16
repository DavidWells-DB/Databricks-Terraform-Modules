data "databricks_aws_bucket_policy" "this" {
  provider      = databricks.account
  bucket        = var.bucket_name
  aws_partition = var.aws_partition
}

# tfsec:ignore:aws-s3-enable-bucket-logging
# Logging for the DBFS root bucket is not a Databricks requirement and is left
# to the root composition to wire (e.g. pointing to a separate access-log bucket).
# Callers that require access logging should create an aws_s3_bucket_logging
# resource referencing this bucket in their root configuration.
resource "aws_s3_bucket" "this" { #tfsec:ignore:aws-s3-enable-bucket-logging
  bucket        = var.bucket_name
  force_destroy = var.force_destroy
  tags          = var.tags
}

# tfsec:ignore:aws-s3-enable-versioning
# Databricks DBFS root storage must NOT have versioning enabled. Versioning
# interferes with Databricks internal object management and is explicitly
# unsupported for workspace root buckets per Databricks documentation.
resource "aws_s3_bucket_versioning" "this" { #tfsec:ignore:aws-s3-enable-versioning
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = local.sse_algorithm
      kms_master_key_id = local.kms_master_key_id
    }
    bucket_key_enabled = var.kms_key_arn != null ? true : false
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.databricks_aws_bucket_policy.this.json

  # Databricks modifies the bucket policy post-creation when it registers the workspace.
  # External mutation is expected — ignore drift on the policy attribute.
  # See DATABRICKS_RULES.md Rule 3.2.
  lifecycle {
    ignore_changes = [policy]
  }

  depends_on = [aws_s3_bucket_public_access_block.this]
}

resource "databricks_mws_storage_configurations" "this" {
  provider                   = databricks.account
  account_id                 = var.databricks_account_id
  storage_configuration_name = var.storage_configuration_name
  bucket_name                = aws_s3_bucket.this.id

  depends_on = [aws_s3_bucket_policy.this]
}

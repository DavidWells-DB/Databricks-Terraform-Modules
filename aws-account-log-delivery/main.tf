# ---------------------------------------------------------------------------
# S3 bucket
# ---------------------------------------------------------------------------

# Access logging is skipped because this IS the log delivery bucket; logging it to itself
# creates a circular dependency. Cross-region replication and event notifications are
# operational concerns for the caller's root composition.
#checkov:skip=CKV_AWS_18:This IS the log delivery bucket; access-logging it to itself creates a circular dependency. Callers who need access logs should configure a separate logging bucket in the root composition.
#checkov:skip=CKV_AWS_144:Cross-region replication is an operational resilience choice for the caller, not a module concern. Log files are append-only and recoverable from Databricks.
#checkov:skip=CKV2_AWS_62:S3 event notifications for a log delivery sink are an operational concern for the caller's root composition, not module infrastructure.
#checkov:skip=CKV_AWS_145:SSE-S3 (AES-256) is sufficient for log delivery. CMK requires additional KMS inputs beyond module scope; callers needing CMK should configure aws_s3_bucket_server_side_encryption_configuration separately.
#checkov:skip=CKV_AWS_21:Versioning is intentionally disabled for this append-only log delivery workload; lifecycle expiry handles retention instead.
resource "aws_s3_bucket" "this" { #tfsec:ignore:aws-s3-enable-bucket-logging
  bucket        = "${var.resource_prefix}-log-delivery"
  force_destroy = var.force_destroy
  tags          = merge(var.tags, { Name = "${var.resource_prefix}-log-delivery" })
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versioning is intentionally disabled: Databricks log delivery is append-only and produces
# large volumes of immutable objects. Versioning would double storage costs with no recovery
# benefit for this write-once workload. Lifecycle expiry handles retention.
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Disabled" #tfsec:ignore:aws-s3-enable-versioning
  }
}

# SSE-S3 (AES-256) encryption at rest. CMK encryption is omitted from this module because
# it requires KMS key inputs and cross-service IAM wiring that are an operational concern
# for callers who require it.
#checkov:skip=CKV_AWS_145:SSE-S3 (AES-256) is sufficient for log delivery. CMK requires additional KMS inputs beyond module scope.
resource "aws_s3_bucket_server_side_encryption_configuration" "this" { #tfsec:ignore:aws-s3-encryption-customer-key
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lifecycle configuration: expire log objects after the configured number of days.
# Satisfies CKV2_AWS_61 and provides cost control for the log storage bucket.
#checkov:skip=CKV_AWS_300:Aborting failed multipart uploads is not applicable; Databricks log delivery uses single-part PutObject writes, not multipart uploads.
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "expire-logs"
    status = "Enabled"

    expiration {
      days = var.log_retention_days
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}

# ---------------------------------------------------------------------------
# IAM role for log delivery
# ---------------------------------------------------------------------------

data "databricks_aws_assume_role_policy" "this" {
  provider         = databricks.account
  external_id      = var.databricks_account_id
  for_log_delivery = true
  aws_partition    = var.aws_partition
}

resource "aws_iam_role" "this" {
  name               = "${var.resource_prefix}-log-delivery"
  description        = "Databricks log delivery role for account ${var.databricks_account_id}"
  assume_role_policy = data.databricks_aws_assume_role_policy.this.json
  tags               = merge(var.tags, { Name = "${var.resource_prefix}-log-delivery" })
}

# ---------------------------------------------------------------------------
# S3 bucket policy — grants the log delivery IAM role full access.
# Databricks writes log files into this bucket using the role.
# ---------------------------------------------------------------------------

data "databricks_aws_bucket_policy" "this" {
  provider         = databricks.account
  full_access_role = aws_iam_role.this.arn
  aws_partition    = var.aws_partition
  bucket           = aws_s3_bucket.this.bucket
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.databricks_aws_bucket_policy.this.json

  depends_on = [aws_s3_bucket_public_access_block.this]
}

# ---------------------------------------------------------------------------
# IAM propagation sleep
# databricks_mws_credentials fails if the IAM role hasn't propagated through
# AWS global IAM yet. 30s is the documented minimum; matches the pattern in
# the credentials module (DATABRICKS_RULES.md Rule 3.1).
# ---------------------------------------------------------------------------

resource "time_sleep" "iam_propagation" {
  depends_on      = [aws_iam_role.this]
  create_duration = "30s"
}

# ---------------------------------------------------------------------------
# Databricks credentials registration (log delivery role)
# ---------------------------------------------------------------------------

resource "databricks_mws_credentials" "this" {
  provider         = databricks.account
  credentials_name = "${var.resource_prefix}-log-delivery"
  role_arn         = aws_iam_role.this.arn

  depends_on = [time_sleep.iam_propagation]
}

# ---------------------------------------------------------------------------
# Databricks storage configuration (log delivery bucket)
# ---------------------------------------------------------------------------

resource "databricks_mws_storage_configurations" "this" {
  provider                   = databricks.account
  account_id                 = var.databricks_account_id
  storage_configuration_name = "${var.resource_prefix}-log-delivery"
  bucket_name                = aws_s3_bucket.this.bucket
}

# ---------------------------------------------------------------------------
# Log delivery configurations — one per requested log_type
# ---------------------------------------------------------------------------

resource "databricks_mws_log_delivery" "this" {
  provider = databricks.account
  for_each = toset(var.log_types)

  account_id               = var.databricks_account_id
  credentials_id           = databricks_mws_credentials.this.credentials_id
  storage_configuration_id = databricks_mws_storage_configurations.this.storage_configuration_id
  log_type                 = each.key
  output_format            = "JSON"
  delivery_path_prefix     = local.log_type_config[each.key].delivery_path_prefix
  config_name              = "${var.resource_prefix}-${local.log_type_config[each.key].config_name}"
}

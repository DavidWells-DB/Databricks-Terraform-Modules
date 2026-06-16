# Dependency ordering for the AWS → Databricks trust relationship:
#
# 1. databricks_storage_credential (this) — created first with a pre-computed IAM
#    role ARN. Databricks generates the external_id at this point without the AWS
#    role yet existing. skip_validation = true suppresses the check.
#
# 2. aws_iam_role (this) — built after the storage credential exists because its
#    trust policy needs databricks_storage_credential.this.aws_iam_role[0].external_id.
#    This is what prevents the confused deputy problem.
#
# 3. time_sleep.iam_propagation — 30 s after the IAM role policy is attached.
#    Databricks validates the trust relationship on credential reads; the role must
#    be globally visible before that check runs.
#
# This pattern avoids the circular dependency by pre-computing the IAM role ARN
# (aws_partition + aws_account_id + role_name) rather than referencing it from the
# aws_iam_role resource itself.

# Step 1 — register the storage credential to obtain the Databricks-generated external_id.
resource "databricks_storage_credential" "this" {
  provider = databricks.workspace

  name = var.credential_name
  aws_iam_role {
    role_arn = "arn:${var.aws_partition}:iam::${var.aws_account_id}:role/${var.role_name}"
  }

  comment         = var.comment
  isolation_mode  = var.isolation_mode
  skip_validation = true # IAM role does not exist yet; validated on subsequent applies.
}

# Step 2 — generate the scoped S3 access policy for the IAM role.
data "databricks_aws_unity_catalog_policy" "this" {
  provider = databricks.workspace

  aws_account_id = var.aws_account_id
  bucket_name    = var.bucket_name
  role_name      = var.role_name
  kms_name       = var.kms_key_arn
  aws_partition  = var.aws_partition
}

# Step 3 — generate the trust policy using the external_id produced in Step 1.
data "databricks_aws_unity_catalog_assume_role_policy" "this" {
  provider = databricks.workspace

  aws_account_id        = var.aws_account_id
  aws_partition         = var.aws_partition
  role_name             = var.role_name
  unity_catalog_iam_arn = local.unity_catalog_iam_arn
  external_id           = databricks_storage_credential.this.aws_iam_role[0].external_id
}

# Step 4 — create the AWS IAM role with the correct trust policy.
resource "aws_iam_role" "this" {
  name               = var.role_name
  assume_role_policy = data.databricks_aws_unity_catalog_assume_role_policy.this.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "this" {
  name   = "${var.role_name}-uc-policy"
  role   = aws_iam_role.this.id
  policy = data.databricks_aws_unity_catalog_policy.this.json
}

# IAM role propagation: Databricks validates the trust relationship when the storage
# credential is read or updated. The IAM role must be globally visible before that
# check runs. 30 s is the documented minimum for IAM propagation.
# Per DATABRICKS_RULES.md Rule 3.1.
resource "time_sleep" "iam_propagation" {
  depends_on      = [aws_iam_role_policy.this]
  create_duration = "30s"
}

# The metastore's ROOT-STORAGE credential at the ACCOUNT plane (AWS): one
# databricks_metastore_data_access bound to the GIVEN metastore_id, plus the IAM role
# whose trust policy matches THAT credential's external_id.
#
# WHY THIS MODULE (the design fix, 2026-11-10): the previous composition registered the
# metastore's root credential through a WORKSPACE-scoped databricks_storage_credential
# — which lands on the workspace's AUTO-ASSIGNED default metastore, not the new one —
# and reused that workspace-plane credential's external_id in the metastore's
# data-access, so the IAM trust pointed at the wrong credential (broken access). Here
# the data access IS the credential (metastore-scoped, account plane, the right
# metastore by construction), and the trust is built around ITS external_id. No
# duplicate data-access object exists.
#
# Dependency ordering (same choreography as aws-uc-storage-credential, adapted):
#   1. databricks_metastore_data_access — created first with a PRE-COMPUTED role ARN;
#      Databricks generates the external_id at this point.
#   2. The IAM trust policy is built FROM that external_id, then the role is created.
#   3. time_sleep — IAM propagation before the credential is (re)validated.
resource "databricks_metastore_data_access" "this" {
  provider = databricks.account

  metastore_id = var.metastore_id
  name         = var.credential_name
  is_default   = true
  comment      = var.comment

  aws_iam_role {
    role_arn = "arn:${var.aws_partition}:iam::${var.aws_account_id}:role/${var.role_name}"
  }

  skip_validation = var.skip_validation
}

data "databricks_aws_unity_catalog_policy" "this" {
  provider = databricks.account

  aws_account_id = var.aws_account_id
  bucket_name    = var.bucket_name
  role_name      = var.role_name
  aws_partition  = var.aws_partition
}

data "databricks_aws_unity_catalog_assume_role_policy" "this" {
  provider = databricks.account

  aws_account_id        = var.aws_account_id
  aws_partition         = var.aws_partition
  role_name             = var.role_name
  unity_catalog_iam_arn = local.unity_catalog_iam_arn
  external_id           = databricks_metastore_data_access.this.aws_iam_role[0].external_id
}

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

# IAM propagation: Databricks validates the trust relationship on credential reads;
# the role must be globally visible before that check runs. 30s is the documented
# minimum (Rule 3.1).
resource "time_sleep" "iam_propagation" {
  depends_on      = [aws_iam_role_policy.this]
  create_duration = "30s"
}

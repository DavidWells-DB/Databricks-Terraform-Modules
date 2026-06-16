data "databricks_aws_assume_role_policy" "this" {
  provider      = databricks.account
  external_id   = var.databricks_account_id
  aws_partition = var.aws_partition
}

data "databricks_aws_crossaccount_policy" "this" {
  provider      = databricks.account
  aws_partition = var.aws_partition
}

resource "aws_iam_role" "this" {
  name               = var.role_name
  assume_role_policy = data.databricks_aws_assume_role_policy.this.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "this" {
  name   = "${var.role_name}-policy"
  role   = aws_iam_role.this.id
  policy = data.databricks_aws_crossaccount_policy.this.json
}

# IAM role propagation: databricks_mws_credentials below fails if it references
# the role before AWS has propagated it. 30s is the documented minimum.
resource "time_sleep" "iam_propagation" {
  depends_on      = [aws_iam_role_policy.this]
  create_duration = "30s"
}

resource "databricks_mws_credentials" "this" {
  provider         = databricks.account
  credentials_name = var.credentials_name
  role_arn         = aws_iam_role.this.arn

  depends_on = [time_sleep.iam_propagation]
}

# Minimal cross-account IAM role for testing encryption-keys module
# The encryption-keys module needs a cross-account role ARN to add to the workspace-storage key policy

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "cross_account_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::414351767826:root"] # Databricks commercial account
    }
    actions = ["sts:AssumeRole"]
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.databricks_account_id]
    }
  }
}

resource "aws_iam_role" "test_cross_account" {
  name               = "tftest-encryption-keys-cross-account"
  assume_role_policy = data.aws_iam_policy_document.cross_account_assume_role.json
  tags = {
    Purpose = "tftest-integration"
  }
}

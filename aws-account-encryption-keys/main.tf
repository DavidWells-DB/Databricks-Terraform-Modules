# ---------------------------------------------------------------------------
# Managed-services CMK
# Encrypts workspace objects stored in the Databricks control plane:
# notebooks, secrets, Databricks SQL queries, and SQL query history.
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "managed_services" {
  version = "2012-10-17"

  statement {
    sid    = "EnableIAMUserPermissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [local.customer_account_arn]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowDatabricksControlPlane"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [local.databricks_control_plane_arn]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
    ]
    resources = ["*"]
  }
}

resource "aws_kms_key" "managed_services" {
  description             = "Databricks managed-services CMK — encrypts notebooks, secrets, SQL history"
  policy                  = data.aws_iam_policy_document.managed_services.json
  enable_key_rotation     = true
  deletion_window_in_days = 7
  tags                    = var.tags
}

resource "aws_kms_alias" "managed_services" {
  name          = var.managed_services_key_alias
  target_key_id = aws_kms_key.managed_services.key_id
}

resource "databricks_mws_customer_managed_keys" "managed_services" {
  provider   = databricks.account
  account_id = var.databricks_account_id

  aws_key_info {
    key_arn   = aws_kms_key.managed_services.arn
    key_alias = aws_kms_alias.managed_services.name
  }

  use_cases = ["MANAGED_SERVICES"]
}

# ---------------------------------------------------------------------------
# Workspace-storage CMK
# Encrypts the workspace root S3 bucket (DBFS) and cluster EBS volumes.
# The cross-account role ARN is required in the key policy so that EC2
# instances launched by the workspace can use the key for EBS encryption.
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "workspace_storage" {
  version = "2012-10-17"

  statement {
    sid    = "EnableIAMUserPermissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [local.customer_account_arn]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowDatabricksForDBFS"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [local.databricks_control_plane_arn]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowDatabricksDBFSGrants"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [local.databricks_control_plane_arn]
    }
    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant",
    ]
    resources = ["*"]
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }

  statement {
    sid    = "AllowCrossAccountRoleForEBS"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [var.cross_account_role_arn]
    }
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
      "kms:DescribeKey",
    ]
    resources = ["*"]
    condition {
      test     = "ForAnyValue:StringLike"
      variable = "kms:ViaService"
      values   = ["ec2.*.amazonaws.com"]
    }
  }
}

resource "aws_kms_key" "workspace_storage" {
  description             = "Databricks workspace-storage CMK — encrypts DBFS root bucket and cluster EBS volumes"
  policy                  = data.aws_iam_policy_document.workspace_storage.json
  enable_key_rotation     = true
  deletion_window_in_days = 7
  tags                    = var.tags
}

resource "aws_kms_alias" "workspace_storage" {
  name          = var.workspace_storage_key_alias
  target_key_id = aws_kms_key.workspace_storage.key_id
}

resource "databricks_mws_customer_managed_keys" "workspace_storage" {
  provider   = databricks.account
  account_id = var.databricks_account_id

  aws_key_info {
    key_arn   = aws_kms_key.workspace_storage.arn
    key_alias = aws_kms_alias.workspace_storage.name
  }

  use_cases = ["STORAGE"]
}

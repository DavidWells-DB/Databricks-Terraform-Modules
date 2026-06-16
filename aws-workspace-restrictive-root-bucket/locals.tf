locals {
  # Databricks control plane uses distinct AWS account IDs per gov shard.
  # The bucket policy's principal condition must reference the correct one.
  # Source: https://docs.databricks.com/aws/en/security/privacy/gov-cloud
  databricks_aws_account_id = (
    var.databricks_gov_shard == "civilian" ? "044793339203" :
    var.databricks_gov_shard == "dod" ? "170661010020" :
    "414351767826"
  )

  # Construct the restrictive bucket policy JSON
  # Scopes write access to workspace-specific paths while allowing read broadly.
  # Enforces principal tag condition and SSL-only access.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowDatabricksReadAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${var.aws_partition}:iam::${local.databricks_aws_account_id}:root"
        }
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "arn:${var.aws_partition}:s3:::${var.bucket_name}/*",
          "arn:${var.aws_partition}:s3:::${var.bucket_name}"
        ]
        Condition = {
          StringEquals = {
            "aws:PrincipalTag/DatabricksAccountId" = var.databricks_account_id
          }
        }
      },
      {
        Sid    = "AllowDatabricksWriteAccessWorkspacePaths"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${var.aws_partition}:iam::${local.databricks_aws_account_id}:root"
        }
        Action = [
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:${var.aws_partition}:s3:::${var.bucket_name}/ephemeral/${var.region}-prod/${var.workspace_id}/*",
          "arn:${var.aws_partition}:s3:::${var.bucket_name}/user/hive/warehouse/*",
          "arn:${var.aws_partition}:s3:::${var.bucket_name}/FileStore/*"
        ]
        Condition = {
          StringEquals = {
            "aws:PrincipalTag/DatabricksAccountId" = var.databricks_account_id
          }
        }
      },
      {
        Sid    = "DenyNonSSLAccess"
        Effect = "Deny"
        Principal = {
          AWS = "*"
        }
        Action = "s3:*"
        Resource = [
          "arn:${var.aws_partition}:s3:::${var.bucket_name}/*",
          "arn:${var.aws_partition}:s3:::${var.bucket_name}"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

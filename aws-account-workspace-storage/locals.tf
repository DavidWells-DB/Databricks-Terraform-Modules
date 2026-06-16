locals {
  # Databricks control plane uses distinct AWS account IDs per gov shard.
  # The bucket policy must trust the correct one.
  # Source: https://docs.databricks.com/aws/en/security/privacy/gov-cloud
  databricks_aws_account_id = (
    var.databricks_gov_shard == "civilian" ? "044793339203" :
    var.databricks_gov_shard == "dod" ? "170661010020" :
    "414351767826"
  )

  # SSE-KMS when a key ARN is provided; SSE-S3 otherwise.
  # GovCloud workspaces require KMS (kms_key_arn must be set).
  sse_algorithm     = var.kms_key_arn != null ? "aws:kms" : "AES256"
  kms_master_key_id = var.kms_key_arn != null ? var.kms_key_arn : null
}

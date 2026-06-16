locals {
  # Databricks control plane AWS account IDs differ per gov shard.
  # The KMS key policies must trust the correct control plane account.
  # Source: https://docs.databricks.com/aws/en/security/privacy/gov-cloud
  databricks_aws_account_id = (
    var.databricks_gov_shard == "civilian" ? "044793339203" :
    var.databricks_gov_shard == "dod" ? "170661010020" :
    "414351767826"
  )

  databricks_control_plane_arn = "arn:${var.aws_partition}:iam::${local.databricks_aws_account_id}:root"
  customer_account_arn         = "arn:${var.aws_partition}:iam::${var.aws_account_id}:root"
}

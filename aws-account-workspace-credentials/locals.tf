locals {
  # Databricks control plane uses distinct AWS account IDs per gov shard.
  # The IAM role's assume-role policy must trust the correct one.
  # Source: https://docs.databricks.com/aws/en/security/privacy/gov-cloud
  databricks_aws_account_id = (
    var.databricks_gov_shard == "civilian" ? "044793339203" :
    var.databricks_gov_shard == "dod" ? "170661010020" :
    "414351767826"
  )
}

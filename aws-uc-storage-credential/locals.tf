locals {
  # Databricks Unity Catalog IAM role ARN differs per gov shard.
  # The trust policy must reference the correct Databricks-managed master role.
  # Source: https://docs.databricks.com/aws/en/security/privacy/gov-cloud
  # and databricks_aws_unity_catalog_assume_role_policy provider defaults.
  unity_catalog_iam_arn = (
    var.databricks_gov_shard == "civilian" ? "arn:aws-us-gov:iam::044793339203:role/unity-catalog-prod-UCMasterRole-1QRFA8SGY15OJ" :
    var.databricks_gov_shard == "dod" ? "arn:aws-us-gov:iam::170661010020:role/unity-catalog-prod-UCMasterRole-1DI6DL6ZP26AS" :
    "arn:aws:iam::414351767826:role/unity-catalog-prod-UCMasterRole-14S5ZJVKOTYTL"
  )
}

locals {
  # Databricks account console host varies by GovCloud shard.
  # Source: https://docs.databricks.com/aws/en/security/privacy/gov-cloud
  databricks_account_host = (
    var.databricks_gov_shard == "civilian" ? "https://accounts.cloud.databricks.us" :
    var.databricks_gov_shard == "dod" ? "https://accounts-dod.cloud.databricks.mil" :
    "https://accounts.cloud.databricks.com"
  )
}

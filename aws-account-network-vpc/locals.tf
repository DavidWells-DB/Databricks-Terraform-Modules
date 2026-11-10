locals {
  # Databricks account host URL, derived from gov_shard, for documentation and output use.
  # The actual provider configuration (host =) lives in the root composition;
  # this local is exposed as an output to help callers validate their provider config.
  # Source: https://docs.databricks.com/aws/en/security/privacy/gov-cloud
  databricks_account_host = (
    var.databricks_gov_shard == "civilian" ? "https://accounts.cloud.databricks.us" :
    var.databricks_gov_shard == "dod" ? "https://accounts-dod.cloud.databricks.mil" :
    "https://accounts.cloud.databricks.com"
  )
}

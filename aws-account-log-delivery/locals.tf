locals {
  # Databricks control plane uses distinct AWS account IDs per gov shard.
  # The IAM role's assume-role policy must trust the correct one.
  # Source: https://docs.databricks.com/aws/en/security/privacy/gov-cloud
  databricks_aws_account_id = (
    var.databricks_gov_shard == "civilian" ? "044793339203" :
    var.databricks_gov_shard == "dod" ? "170661010020" :
    "414351767826"
  )

  # Delivery path prefix and config name keyed by log_type.
  # AUDIT_LOGS and BILLABLE_USAGE each land in their own S3 prefix.
  log_type_config = {
    AUDIT_LOGS     = { delivery_path_prefix = "audit-logs", config_name = "Audit Logs" }
    BILLABLE_USAGE = { delivery_path_prefix = "billable-usage", config_name = "Billable Usage" }
  }
}

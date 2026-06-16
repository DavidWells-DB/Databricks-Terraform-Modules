locals {
  # Databricks control plane uses distinct AWS account IDs per gov shard.
  # The VPC endpoint service allowed principal must trust the correct one.
  # Source: https://docs.databricks.com/aws/en/security/privacy/gov-cloud
  databricks_aws_account_id = (
    var.databricks_gov_shard == "civilian" ? "044793339203" :
    var.databricks_gov_shard == "dod" ? "170661010020" :
    "414351767826"
  )

  # If listener_port is not specified, use target_port
  effective_listener_port = coalesce(var.listener_port, var.target_port)

  # Construct the principal ARN for VPC endpoint service authorization
  databricks_principal_arn = "arn:${var.aws_partition}:iam::${local.databricks_aws_account_id}:root"
}

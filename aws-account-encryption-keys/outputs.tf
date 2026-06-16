output "managed_services_key_id" {
  description = "Databricks CMK object ID for managed services. Pass as managed_services_customer_managed_key_id to workspace creation modules."
  value       = databricks_mws_customer_managed_keys.managed_services.customer_managed_key_id
}

output "workspace_storage_key_id" {
  description = "Databricks CMK object ID for workspace storage. Pass as storage_customer_managed_key_id to workspace creation modules."
  value       = databricks_mws_customer_managed_keys.workspace_storage.customer_managed_key_id
}

output "managed_services_key_arn" {
  description = "ARN of the AWS KMS key used for managed-services encryption."
  value       = aws_kms_key.managed_services.arn
}

output "workspace_storage_key_arn" {
  description = "ARN of the AWS KMS key used for workspace-storage encryption (DBFS, EBS)."
  value       = aws_kms_key.workspace_storage.arn
}

output "managed_services_key_alias" {
  description = "Name of the AWS KMS alias for the managed-services key."
  value       = aws_kms_alias.managed_services.name
}

output "workspace_storage_key_alias" {
  description = "Name of the AWS KMS alias for the workspace-storage key."
  value       = aws_kms_alias.workspace_storage.name
}

output "databricks_control_plane_aws_account_id" {
  description = "Databricks control plane AWS account ID used in KMS key policies. Derived from databricks_gov_shard. Useful for verification and downstream policy construction."
  value       = local.databricks_aws_account_id
}

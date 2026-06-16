output "bucket_name" {
  description = "Name of the S3 bucket that receives Databricks log files."
  value       = aws_s3_bucket.this.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket that receives Databricks log files."
  value       = aws_s3_bucket.this.arn
}

output "role_arn" {
  description = "ARN of the AWS IAM role used by Databricks to write log files to the S3 bucket."
  value       = aws_iam_role.this.arn
}

output "credentials_id" {
  description = "Databricks credentials object ID for the log delivery IAM role."
  value       = databricks_mws_credentials.this.credentials_id
}

output "storage_configuration_id" {
  description = "Databricks storage configuration ID for the log delivery S3 bucket."
  value       = databricks_mws_storage_configurations.this.storage_configuration_id
}

output "log_delivery_configuration_ids" {
  description = "Map of log_type to databricks_mws_log_delivery configuration ID (e.g. { AUDIT_LOGS = \"...\", BILLABLE_USAGE = \"...\" })."
  value       = { for k, v in databricks_mws_log_delivery.this : k => v.config_id }
}

output "databricks_aws_account_id" {
  description = "Databricks control plane AWS account ID used in the IAM role trust policy. Computed from databricks_gov_shard. Useful for verification and downstream policy construction."
  value       = local.databricks_aws_account_id
}

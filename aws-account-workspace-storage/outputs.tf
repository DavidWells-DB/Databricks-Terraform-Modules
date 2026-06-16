output "storage_configuration_id" {
  description = "Databricks storage configuration ID. Pass to workspace creation modules as the storage_configuration_id input."
  value       = databricks_mws_storage_configurations.this.storage_configuration_id
}

output "bucket_name" {
  description = "Name of the S3 bucket created for workspace root storage (DBFS)."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket. Useful for downstream IAM policy references."
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "Bucket-regional domain name (e.g. bucket.s3.us-east-1.amazonaws.com). Useful for endpoint configuration."
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "databricks_aws_account_id" {
  description = "Databricks control plane AWS account ID computed from databricks_gov_shard. Useful for verification and downstream trust-policy construction."
  value       = local.databricks_aws_account_id
}

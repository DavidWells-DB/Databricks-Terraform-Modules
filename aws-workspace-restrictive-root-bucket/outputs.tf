output "bucket_policy_id" {
  description = "S3 bucket policy resource ID (format: bucket_name). Use in depends_on when ordering post-workspace policy updates."
  value       = aws_s3_bucket_policy.this.id
}

output "bucket_name" {
  description = "Name of the S3 bucket to which the restrictive policy was applied."
  value       = aws_s3_bucket_policy.this.bucket
}

output "databricks_aws_account_id" {
  description = "Databricks control plane AWS account ID used in the bucket policy's principal. Computed from databricks_gov_shard. Useful for verification and downstream policy construction."
  value       = local.databricks_aws_account_id
}

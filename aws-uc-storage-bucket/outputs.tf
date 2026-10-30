output "bucket_name" {
  description = "Name of the dedicated UC bucket."
  value       = aws_s3_bucket.this.bucket
}

output "bucket_arn" {
  description = "ARN of the dedicated UC bucket."
  value       = aws_s3_bucket.this.arn
}

output "storage_root" {
  description = "The Unity Catalog storage-root URL for this bucket (s3://<bucket>). Append the catalog's path suffix at the composition."
  value       = "s3://${aws_s3_bucket.this.bucket}"
}

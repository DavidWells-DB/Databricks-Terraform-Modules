output "data_access_id" {
  description = "The metastore data access ID (the root-storage credential on the GIVEN metastore)."
  value       = databricks_metastore_data_access.this.id
}

output "iam_role_arn" {
  description = "The IAM role ARN created for the credential (trust policy built from THIS credential's external_id)."
  value       = aws_iam_role.this.arn
}

output "external_id" {
  description = "The credential's external_id (the trust-policy binding — export for audit)."
  value       = databricks_metastore_data_access.this.aws_iam_role[0].external_id
}

output "storage_credential_id" {
  description = "Unique ID of the Databricks Unity Catalog storage credential. Use this when referencing the credential in external location or metastore data access resources."
  value       = databricks_storage_credential.this.storage_credential_id
}

output "storage_credential_name" {
  description = "Name of the Databricks Unity Catalog storage credential."
  value       = databricks_storage_credential.this.name
}

output "iam_role_arn" {
  description = "ARN of the AWS IAM role created for Unity Catalog storage access."
  value       = aws_iam_role.this.arn
}

output "iam_role_name" {
  description = "Name of the AWS IAM role created for Unity Catalog storage access."
  value       = aws_iam_role.this.name
}

output "external_id" {
  description = "Databricks-generated external ID embedded in the IAM role trust policy. Useful for auditing the confused-deputy protection on the trust relationship."
  value       = databricks_storage_credential.this.aws_iam_role[0].external_id
}

output "unity_catalog_iam_arn" {
  description = "Databricks Unity Catalog master role ARN used in the IAM trust policy. Computed from databricks_gov_shard. Useful for verification and downstream policy auditing."
  value       = local.unity_catalog_iam_arn
}

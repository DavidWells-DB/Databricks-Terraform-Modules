output "credentials_id" {
  description = "Databricks credentials object ID. Pass to workspace creation modules as the credentials_id input."
  value       = databricks_mws_credentials.this.credentials_id
}

output "role_arn" {
  description = "ARN of the AWS IAM cross-account role."
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Name of the AWS IAM cross-account role."
  value       = aws_iam_role.this.name
}

output "databricks_aws_account_id" {
  description = "Databricks control plane AWS account ID used in the role's trust policy. Computed from databricks_gov_shard. Useful for verification and downstream policy construction."
  value       = local.databricks_aws_account_id
}

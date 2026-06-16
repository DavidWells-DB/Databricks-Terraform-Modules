output "service_account_email" {
  description = "Email address of the GCP service account. Used as the Databricks user identity and in IAM bindings."
  value       = google_service_account.this.email
}

output "service_account_id" {
  description = "Fully-qualified GCP service account resource ID (projects/<project>/serviceAccounts/<email>). Use this as service_account_id in IAM member resources."
  value       = google_service_account.this.name
}

output "service_account_unique_id" {
  description = "GCP-assigned unique ID for the service account. Stable across renames; use for IAM policy conditions."
  value       = google_service_account.this.unique_id
}

output "custom_role_id" {
  description = "Fully-qualified custom IAM role name (projects/<project>/roles/<role_id>). Pass to downstream IAM bindings if the role is reused."
  value       = google_project_iam_custom_role.this.name
}

output "databricks_user_id" {
  description = "Databricks account-level user ID of the registered service account. Useful for constructing additional Databricks grants."
  value       = databricks_user.this.id
}

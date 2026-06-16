output "storage_credential_id" {
  description = "Databricks Unity Catalog storage credential ID. Pass to databricks_external_location or databricks_metastore_data_access as the storage_credential_name input."
  value       = databricks_storage_credential.this.id
}

output "databricks_service_account_email" {
  description = "Email address of the Databricks-managed GCP service account. Use this to grant additional GCP IAM permissions beyond the default bucket access."
  value       = databricks_storage_credential.this.databricks_gcp_service_account[0].email
}

output "storage_credential_name" {
  description = "Name of the Databricks Unity Catalog storage credential, as registered in the metastore."
  value       = databricks_storage_credential.this.name
}

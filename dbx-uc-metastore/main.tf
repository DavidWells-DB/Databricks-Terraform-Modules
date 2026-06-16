resource "databricks_metastore" "this" {
  provider      = databricks.account
  name          = var.metastore_name
  region        = var.region
  storage_root  = var.storage_root_url
  owner         = var.owner_group
  force_destroy = true
}

resource "databricks_metastore_data_access" "this" {
  provider     = databricks.account
  metastore_id = databricks_metastore.this.id
  name         = var.data_access_name
  is_default   = true

  dynamic "aws_iam_role" {
    for_each = var.storage_credential.aws_iam_role != null ? [var.storage_credential.aws_iam_role] : []
    iterator = cred
    content {
      role_arn = cred.value.role_arn
    }
  }

  dynamic "azure_managed_identity" {
    for_each = var.storage_credential.azure_managed_identity != null ? [var.storage_credential.azure_managed_identity] : []
    iterator = cred
    content {
      access_connector_id = cred.value.access_connector_id
      managed_identity_id = cred.value.managed_identity_id
    }
  }

  dynamic "databricks_gcp_service_account" {
    for_each = var.storage_credential.databricks_gcp_service_account != null ? [var.storage_credential.databricks_gcp_service_account] : []
    content {
    }
  }
}

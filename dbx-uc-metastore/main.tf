resource "databricks_metastore" "this" {
  provider      = databricks.account
  name          = var.metastore_name
  region        = var.region
  storage_root  = var.storage_root_url
  owner         = var.owner_group
  force_destroy = true
}

resource "databricks_metastore_data_access" "this" {
  # Only created when a storage credential is supplied; a storageless metastore
  # (no storage_root_url, no storage_credential) skips this entirely.
  count = var.storage_credential != null ? 1 : 0

  provider     = databricks.account
  metastore_id = databricks_metastore.this.id
  name         = var.data_access_name
  is_default   = true

  lifecycle {
    precondition {
      condition     = var.data_access_name != null
      error_message = "data_access_name is required when storage_credential is set."
    }
  }

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

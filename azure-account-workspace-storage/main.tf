# tfsec:ignore:azure-storage-queue-services-logging-enabled
# Queue service logging is not applicable to Databricks ADLS Gen2 storage accounts,
# which are used exclusively as blob/DFS endpoints. Queue logging is a no-op here.
#checkov:skip=CKV_AZURE_33:Queue service logging is not applicable; this storage account is used only as an ADLS Gen2 DFS endpoint for Databricks, not as a queue service.
#checkov:skip=CKV2_AZURE_21:Blob read request logging is not applicable; Databricks accesses ADLS Gen2 via the Access Connector managed identity, not the blob service API directly.
#checkov:skip=CKV2_AZURE_33:Private endpoint wiring is a root-composition concern; this module creates the storage account only. Callers that require PE connectivity should create azurerm_private_endpoint referencing this module's storage_account_id output.
resource "azurerm_storage_account" "this" {
  name                     = local.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  account_kind             = "StorageV2"

  # ADLS Gen2: hierarchical namespace required for Unity Catalog metastore storage
  # and Databricks workspace root storage on Azure.
  is_hns_enabled = true

  min_tls_version            = var.min_tls_version
  https_traffic_only_enabled = true

  # Disable public blob access; Databricks accesses storage via the DFS endpoint
  # using the Access Connector's managed identity — not public blob access.
  allow_nested_items_to_be_public = false

  # CKV_AZURE_59: Explicitly disable public network access. Databricks accesses
  # ADLS Gen2 via the DFS endpoint using the Access Connector's managed identity.
  public_network_access_enabled = false

  # For Databricks ADLS Gen2, the Access Connector's managed identity is the only
  # principal that needs access; shared key auth and local users are not required.
  shared_access_key_enabled = false
  local_user_enabled        = false

  # CKV2_AZURE_38: Enable soft-delete for blob and container to allow recovery of
  # accidentally deleted data. 7-day retention is a safe minimum; adjust at root.
  blob_properties {
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }

  dynamic "identity" {
    for_each = local.use_cmk ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  dynamic "customer_managed_key" {
    for_each = local.use_cmk ? [1] : []
    content {
      key_vault_key_id          = var.kms_key_id
      user_assigned_identity_id = null
    }
  }

  tags = var.tags
}

resource "azurerm_storage_container" "this" {
  name                  = local.container_name
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}

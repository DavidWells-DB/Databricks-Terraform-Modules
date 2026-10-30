# A dedicated ADLS Gen2 storage account + container for a Unity Catalog catalog's
# MANAGED storage.
#
# BEST PRACTICE (recorded in the Blueprints OKF unity-catalog entry, 2026-10-30):
# a catalog's managed storage belongs on a DEDICATED container — not the workspace
# root storage, which the platform's auto-created workspace catalog shares with
# DBFS root and internal workspace storage. This module is the CREATE side of
# create-vs-adopt (Rule 8.4); the adopt side is an existing storage account +
# container path passed directly to the composition (the azure-uc-storage-credential
# module already handles existing accounts).

# tfsec:ignore:azure-storage-queue-services-logging-enabled
# Queue service logging is not applicable to ADLS Gen2 accounts used exclusively
# as DFS endpoints for Unity Catalog.
#checkov:skip=CKV_AZURE_33:Queue service logging is not applicable; this storage account serves only a UC catalog's DFS endpoint.
#checkov:skip=CKV2_AZURE_21:Blob read request logging is not applicable; Databricks accesses ADLS Gen2 via the Access Connector managed identity.
#checkov:skip=CKV2_AZURE_33:Private endpoint wiring is a root-composition concern; callers that require PE connectivity create azurerm_private_endpoint against this module's storage_account_id output.
resource "azurerm_storage_account" "this" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  account_kind             = "StorageV2"

  # ADLS Gen2: hierarchical namespace is required for Unity Catalog storage.
  is_hns_enabled = true

  min_tls_version                 = var.min_tls_version
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false

  tags = var.tags
}

# The dedicated container for the catalog's managed data. Private access only —
# Databricks reads/writes through the Access Connector's managed identity via the
# storage credential (wired by the composition), never via the blob public path.
resource "azurerm_storage_container" "this" {
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}

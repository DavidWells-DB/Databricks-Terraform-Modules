# Create the Azure Databricks Access Connector with a SystemAssigned managed identity.
# This identity is the Azure-side principal that Databricks UC uses to read/write storage.
resource "azurerm_databricks_access_connector" "this" {
  name                = local.access_connector_name
  resource_group_name = var.resource_group_name
  location            = var.location

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Assign Storage Blob Data Contributor to the Access Connector's managed identity
# on the target storage account so Databricks UC can read and write ADLS Gen2 data.
resource "azurerm_role_assignment" "this" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.this.identity[0].principal_id
}

# Register the Access Connector as a Unity Catalog storage credential.
# This is the indivisible cloud-side + Databricks-side pairing per DATABRICKS_RULES Rule 1.4.
resource "databricks_storage_credential" "this" {
  provider = databricks.workspace

  name           = var.credential_name
  comment        = var.comment
  isolation_mode = var.isolation_mode

  azure_managed_identity {
    access_connector_id = azurerm_databricks_access_connector.this.id
  }

  skip_validation = var.skip_validation

  depends_on = [azurerm_role_assignment.this]
}

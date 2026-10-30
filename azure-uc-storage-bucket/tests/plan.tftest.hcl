mock_provider "azurerm" {
  mock_resource "azurerm_storage_account" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Storage/storageAccounts/mycatalogucst"
      name = "mycatalogucst"
    }
  }

  mock_resource "azurerm_storage_container" {
    defaults = {
      id = "https://mycatalogucst.blob.core.windows.net/catalog"
    }
  }
}

variables {
  storage_account_name = "mycatalogucst"
  resource_group_name  = "test-rg"
  location             = "eastus"
}

run "storage_account_is_adls_gen2_private" {
  command = plan

  assert {
    condition     = azurerm_storage_account.this.is_hns_enabled == true && azurerm_storage_account.this.allow_nested_items_to_be_public == false && azurerm_storage_account.this.https_traffic_only_enabled == true
    error_message = "The account must be HNS-enabled (ADLS Gen2) with no public nested items and HTTPS-only"
  }
}

run "container_is_private_with_default_name" {
  command = plan

  assert {
    condition     = azurerm_storage_container.this.container_access_type == "private" && azurerm_storage_container.this.name == "catalog"
    error_message = "The container must be private, defaulting to the name \"catalog\""
  }
}

run "storage_root_output_is_abfss" {
  command = plan

  assert {
    condition     = output.storage_root == "abfss://catalog@mycatalogucst.dfs.core.windows.net"
    error_message = "storage_root must be the abfss:// DFS URL for the dedicated container"
  }
}

run "replication_validation_rejects_invalid" {
  command = plan

  variables {
    account_replication_type = "RA-GRS"
  }

  expect_failures = [var.account_replication_type]
}

run "account_name_validation_rejects_uppercase" {
  command = plan

  variables {
    storage_account_name = "MyAccount"
  }

  expect_failures = [var.storage_account_name]
}

run "account_name_validation_rejects_too_long" {
  command = plan

  variables {
    storage_account_name = "abcdefghijklmnopqrstuvwxyz0123456789"
  }

  expect_failures = [var.storage_account_name]
}

run "container_name_validation_rejects_uppercase" {
  command = plan

  variables {
    container_name = "Catalog"
  }

  expect_failures = [var.container_name]
}

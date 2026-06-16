mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-databricks-test"
  location            = "eastus"
  resource_prefix     = "testprefix"
}

run "storage_account_name_constructed_from_prefix" {
  command = plan

  assert {
    condition     = azurerm_storage_account.this.name == "testprefixstor"
    error_message = "Storage account name should be resource_prefix + 'stor'"
  }
}

run "default_container_name_is_databricks" {
  command = plan

  assert {
    condition     = azurerm_storage_container.this.name == "databricks"
    error_message = "Default container name should be 'databricks' when container_name is null"
  }
}

run "custom_container_name_is_used" {
  command = plan

  variables {
    container_name = "mycontainer"
  }

  assert {
    condition     = azurerm_storage_container.this.name == "mycontainer"
    error_message = "Custom container name should be passed through to the container resource"
  }
}

run "hns_enabled_on_storage_account" {
  command = plan

  assert {
    condition     = azurerm_storage_account.this.is_hns_enabled == true
    error_message = "ADLS Gen2 hierarchical namespace must be enabled"
  }
}

run "https_only_enabled" {
  command = plan

  assert {
    condition     = azurerm_storage_account.this.https_traffic_only_enabled == true
    error_message = "HTTPS-only must be enforced on the storage account"
  }
}

run "public_access_blocked" {
  command = plan

  assert {
    condition     = azurerm_storage_account.this.allow_nested_items_to_be_public == false
    error_message = "Public blob access must be disabled"
  }
}

run "container_access_type_is_private" {
  command = plan

  assert {
    condition     = azurerm_storage_container.this.container_access_type == "private"
    error_message = "Container access type must be private"
  }
}

run "invalid_resource_prefix_with_uppercase_rejected" {
  command = plan

  variables {
    resource_prefix = "InvalidPrefix"
  }

  expect_failures = [var.resource_prefix]
}

run "invalid_resource_prefix_too_long_rejected" {
  command = plan

  variables {
    resource_prefix = "thisistoolongforprefix"
  }

  expect_failures = [var.resource_prefix]
}

run "invalid_resource_prefix_with_hyphens_rejected" {
  command = plan

  variables {
    resource_prefix = "my-prefix"
  }

  expect_failures = [var.resource_prefix]
}

run "invalid_resource_prefix_empty_rejected" {
  command = plan

  variables {
    resource_prefix = ""
  }

  expect_failures = [var.resource_prefix]
}

run "invalid_container_name_too_short_rejected" {
  command = plan

  variables {
    container_name = "ab"
  }

  expect_failures = [var.container_name]
}

run "invalid_container_name_starts_with_hyphen_rejected" {
  command = plan

  variables {
    container_name = "-mycontainer"
  }

  expect_failures = [var.container_name]
}

run "invalid_container_name_double_hyphen_rejected" {
  command = plan

  variables {
    container_name = "my--container"
  }

  expect_failures = [var.container_name]
}

run "invalid_account_tier_rejected" {
  command = plan

  variables {
    account_tier = "Ultra"
  }

  expect_failures = [var.account_tier]
}

run "invalid_replication_type_rejected" {
  command = plan

  variables {
    account_replication_type = "INVALID"
  }

  expect_failures = [var.account_replication_type]
}

run "invalid_min_tls_version_rejected" {
  command = plan

  variables {
    min_tls_version = "TLS1_3"
  }

  expect_failures = [var.min_tls_version]
}

run "valid_grs_replication_accepted" {
  command = plan

  variables {
    account_replication_type = "GRS"
  }

  assert {
    condition     = azurerm_storage_account.this.account_replication_type == "GRS"
    error_message = "GRS replication type should be accepted and passed through"
  }
}

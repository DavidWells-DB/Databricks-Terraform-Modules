mock_provider "azurerm" {}

mock_provider "databricks" {
  alias = "workspace"
}

variables {
  resource_group_name = "test-rg"
  location            = "eastus"
  storage_account_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Storage/storageAccounts/testaccount"
  credential_name     = "test-cred"
}

# --- Name derivation ---

run "default_connector_name_derived_from_credential_name" {
  command = plan

  assert {
    condition     = azurerm_databricks_access_connector.this.name == "dbx-access-connector-test-cred"
    error_message = "Access Connector name should default to dbx-access-connector-<credential_name>"
  }
}

run "explicit_connector_name_overrides_default" {
  command = plan

  variables {
    access_connector_name = "my-custom-connector"
  }

  assert {
    condition     = azurerm_databricks_access_connector.this.name == "my-custom-connector"
    error_message = "Explicit access_connector_name should override the derived default"
  }
}

# --- Resource attribute checks ---

run "storage_credential_uses_input_name" {
  command = plan

  assert {
    condition     = databricks_storage_credential.this.name == "test-cred"
    error_message = "Storage credential name should match the credential_name input"
  }
}

run "skip_validation_defaults_to_false" {
  command = plan

  assert {
    condition     = databricks_storage_credential.this.skip_validation == false
    error_message = "skip_validation should default to false"
  }
}

run "skip_validation_can_be_set_true" {
  command = plan

  variables {
    skip_validation = true
  }

  assert {
    condition     = databricks_storage_credential.this.skip_validation == true
    error_message = "skip_validation should be true when set"
  }
}

run "access_connector_location_matches_input" {
  command = plan

  assert {
    condition     = azurerm_databricks_access_connector.this.location == "eastus"
    error_message = "Access Connector location should match the location input"
  }
}

run "access_connector_resource_group_matches_input" {
  command = plan

  assert {
    condition     = azurerm_databricks_access_connector.this.resource_group_name == "test-rg"
    error_message = "Access Connector resource_group_name should match the resource_group_name input"
  }
}

# --- Variable validation ---

run "invalid_resource_group_name_rejected" {
  command = plan

  variables {
    resource_group_name = "invalid rg name with spaces!"
  }

  expect_failures = [var.resource_group_name]
}

run "invalid_location_rejected" {
  command = plan

  variables {
    location = "East US"
  }

  expect_failures = [var.location]
}

run "invalid_storage_account_id_rejected" {
  command = plan

  variables {
    storage_account_id = "not-a-valid-arm-id"
  }

  expect_failures = [var.storage_account_id]
}

run "credential_name_empty_rejected" {
  command = plan

  variables {
    credential_name = ""
  }

  expect_failures = [var.credential_name]
}

run "credential_name_invalid_chars_rejected" {
  command = plan

  variables {
    credential_name = "invalid name with spaces"
  }

  expect_failures = [var.credential_name]
}

run "credential_name_too_long_rejected" {
  command = plan

  variables {
    credential_name = "this-credential-name-is-way-too-long-and-exceeds-the-one-hundred-character-conservative-upper-bound-limit"
  }

  expect_failures = [var.credential_name]
}

mock_provider "databricks" {
  alias = "account"

  override_resource {
    target = databricks_mws_workspaces.this
    values = {
      workspace_id    = 123456789012345
      workspace_url   = "https://1234567890.12.gcp.databricks.com"
      deployment_name = "1234567890"
    }
  }
}

mock_provider "time" {}

variables {
  databricks_account_id    = "00000000-0000-0000-0000-000000000000"
  workspace_name           = "test-workspace"
  project_id               = "my-test-project"
  region                   = "us-central1"
  resource_prefix          = "test"
  storage_configuration_id = "mock-storage-id"
  databricks_network_id    = "mock-network-id"
}

run "workspace_resource_uses_input_name" {
  command = plan

  assert {
    condition     = databricks_mws_workspaces.this.workspace_name == "test-workspace"
    error_message = "Workspace resource should use workspace_name input"
  }
}

run "workspace_resource_uses_input_location" {
  command = plan

  assert {
    condition     = databricks_mws_workspaces.this.location == "us-central1"
    error_message = "Workspace resource should use region input as location"
  }
}

run "workspace_resource_uses_input_project_id" {
  command = plan

  assert {
    condition     = databricks_mws_workspaces.this.cloud_resource_container[0].gcp[0].project_id == "my-test-project"
    error_message = "Workspace resource should use project_id input"
  }
}

run "workspace_resource_uses_input_network_id" {
  command = plan

  assert {
    condition     = databricks_mws_workspaces.this.network_id == "mock-network-id"
    error_message = "Workspace resource should use databricks_network_id input"
  }
}

run "workspace_resource_uses_input_storage_id" {
  command = plan

  assert {
    condition     = databricks_mws_workspaces.this.storage_configuration_id == "mock-storage-id"
    error_message = "Workspace resource should use storage_configuration_id input"
  }
}

run "workspace_name_too_short_rejected" {
  command = plan

  variables {
    workspace_name = "ab"
  }

  expect_failures = [var.workspace_name]
}

run "workspace_name_too_long_rejected" {
  command = plan

  variables {
    workspace_name = "this-workspace-name-is-way-too-long-and-exceeds-the-sixty-four-character-limit-yes"
  }

  expect_failures = [var.workspace_name]
}

run "workspace_name_invalid_chars_rejected" {
  command = plan

  variables {
    workspace_name = "invalid name with spaces"
  }

  expect_failures = [var.workspace_name]
}

run "invalid_project_id_rejected" {
  command = plan

  variables {
    project_id = "UPPERCASE_PROJECT"
  }

  expect_failures = [var.project_id]
}

run "invalid_region_rejected" {
  command = plan

  variables {
    region = "not-a-region"
  }

  expect_failures = [var.region]
}

run "invalid_resource_prefix_rejected" {
  command = plan

  variables {
    resource_prefix = "-leading-hyphen"
  }

  expect_failures = [var.resource_prefix]
}

run "resource_prefix_too_long_rejected" {
  command = plan

  variables {
    resource_prefix = "this-prefix-is-way-too-long-for-gcp"
  }

  expect_failures = [var.resource_prefix]
}

run "invalid_account_id_rejected" {
  command = plan

  variables {
    databricks_account_id = "not-a-uuid"
  }

  expect_failures = [var.databricks_account_id]
}

run "psc_not_set_by_default" {
  command = plan

  assert {
    condition     = databricks_mws_workspaces.this.private_access_settings_id == null
    error_message = "private_access_settings_id should be null when not provided"
  }
}

run "psc_set_when_provided" {
  command = plan

  variables {
    private_access_settings_id = "mock-psc-id"
  }

  assert {
    condition     = databricks_mws_workspaces.this.private_access_settings_id == "mock-psc-id"
    error_message = "private_access_settings_id should be set when provided"
  }
}

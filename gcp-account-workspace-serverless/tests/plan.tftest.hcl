mock_provider "databricks" {
  alias = "account"

  override_resource {
    target = databricks_mws_workspaces.this
    values = {
      workspace_id    = 1234567890
      workspace_url   = "https://1234567890.gcp.databricks.com"
      deployment_name = "example-serverless"
    }
  }
}

mock_provider "time" {}

variables {
  databricks_account_id = "00000000-0000-0000-0000-000000000000"
  workspace_name        = "test-workspace"
  project_id            = "my-gcp-project"
  region                = "us-central1"
  resource_prefix       = "example"
}

run "workspace_resource_has_serverless_compute_mode" {
  command = plan

  assert {
    condition     = databricks_mws_workspaces.this.compute_mode == "SERVERLESS"
    error_message = "compute_mode must be SERVERLESS for a serverless workspace"
  }
}

run "workspace_resource_uses_input_name" {
  command = plan

  assert {
    condition     = databricks_mws_workspaces.this.workspace_name == "test-workspace"
    error_message = "workspace_name should match the workspace_name input"
  }
}

run "workspace_deployment_name_uses_resource_prefix" {
  command = plan

  assert {
    condition     = databricks_mws_workspaces.this.deployment_name == "example-serverless"
    error_message = "deployment_name should be <resource_prefix>-serverless"
  }
}

run "workspace_resource_uses_input_region" {
  command = plan

  assert {
    condition     = databricks_mws_workspaces.this.location == "us-central1"
    error_message = "location should match the region input"
  }
}

run "workspace_resource_uses_input_project_id" {
  command = plan

  assert {
    condition     = databricks_mws_workspaces.this.cloud_resource_container[0].gcp[0].project_id == "my-gcp-project"
    error_message = "cloud_resource_container.gcp.project_id should match the project_id input"
  }
}

run "invalid_account_id_not_uuid_rejected" {
  command = plan

  variables {
    databricks_account_id = "not-a-uuid"
  }

  expect_failures = [var.databricks_account_id]
}

run "invalid_account_id_wrong_format_rejected" {
  command = plan

  variables {
    databricks_account_id = "00000000-0000-0000-0000"
  }

  expect_failures = [var.databricks_account_id]
}

run "invalid_project_id_too_short_rejected" {
  command = plan

  variables {
    project_id = "ab"
  }

  expect_failures = [var.project_id]
}

run "invalid_project_id_uppercase_rejected" {
  command = plan

  variables {
    project_id = "My-GCP-Project"
  }

  expect_failures = [var.project_id]
}

run "invalid_region_no_number_rejected" {
  command = plan

  variables {
    region = "us-central"
  }

  expect_failures = [var.region]
}

run "invalid_region_uppercase_rejected" {
  command = plan

  variables {
    region = "US-CENTRAL1"
  }

  expect_failures = [var.region]
}

run "invalid_resource_prefix_uppercase_rejected" {
  command = plan

  variables {
    resource_prefix = "MyPrefix"
  }

  expect_failures = [var.resource_prefix]
}

run "invalid_resource_prefix_too_long_rejected" {
  command = plan

  variables {
    resource_prefix = "this-prefix-is-way-too-long-for-the-constraint"
  }

  expect_failures = [var.resource_prefix]
}

run "invalid_workspace_name_too_short_rejected" {
  command = plan

  variables {
    workspace_name = "ab"
  }

  expect_failures = [var.workspace_name]
}

run "invalid_workspace_name_spaces_rejected" {
  command = plan

  variables {
    workspace_name = "my workspace"
  }

  expect_failures = [var.workspace_name]
}

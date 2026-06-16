mock_provider "databricks" {
  alias = "account"

  override_resource {
    target = databricks_mws_workspaces.this
    values = {
      workspace_id    = 123456789012345
      workspace_url   = "https://adb-123456789012345.0.azuredatabricks.net"
      deployment_name = "adb-123456789012345"
    }
  }

  override_resource {
    target = databricks_mws_ncc_binding.this
    values = {
      binding_id = "mock-binding-id"
    }
  }
}

mock_provider "time" {}

variables {
  databricks_account_id    = "00000000-0000-0000-0000-000000000000"
  workspace_name           = "test-workspace"
  region                   = "us-east-1"
  databricks_gov_shard     = null
  credentials_id           = "mock-credentials-id"
  storage_configuration_id = "mock-storage-id"
  databricks_network_id    = "mock-network-id"
}

run "commercial_shard_uses_commercial_host" {
  command = plan

  assert {
    condition     = output.databricks_host == "https://accounts.cloud.databricks.com"
    error_message = "Commercial shard should resolve to https://accounts.cloud.databricks.com"
  }
}

run "civilian_shard_uses_civilian_host" {
  command = plan

  variables {
    databricks_gov_shard = "civilian"
  }

  assert {
    condition     = output.databricks_host == "https://accounts.cloud.databricks.us"
    error_message = "GovCloud civilian shard should resolve to https://accounts.cloud.databricks.us"
  }
}

run "dod_shard_uses_dod_host" {
  command = plan

  variables {
    databricks_gov_shard = "dod"
  }

  assert {
    condition     = output.databricks_host == "https://accounts-dod.cloud.databricks.mil"
    error_message = "GovCloud DoD shard should resolve to https://accounts-dod.cloud.databricks.mil"
  }
}

run "invalid_gov_shard_rejected" {
  command = plan

  variables {
    databricks_gov_shard = "invalid-shard"
  }

  expect_failures = [var.databricks_gov_shard]
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

run "invalid_region_rejected" {
  command = plan

  variables {
    region = "not-a-region"
  }

  expect_failures = [var.region]
}

run "workspace_resource_uses_input_name" {
  command = plan

  assert {
    condition     = databricks_mws_workspaces.this.workspace_name == "test-workspace"
    error_message = "Workspace resource should use workspace_name input"
  }
}

run "workspace_resource_uses_input_region" {
  command = plan

  assert {
    condition     = databricks_mws_workspaces.this.aws_region == "us-east-1"
    error_message = "Workspace resource should use region input as aws_region"
  }
}

run "ncc_binding_not_created_when_null" {
  command = plan

  variables {
    network_connectivity_config_id = null
  }

  assert {
    condition     = length(databricks_mws_ncc_binding.this) == 0
    error_message = "NCC binding should not be created when network_connectivity_config_id is null"
  }
}

run "ncc_binding_created_when_provided" {
  command = plan

  variables {
    network_connectivity_config_id = "mock-ncc-id"
  }

  assert {
    condition     = length(databricks_mws_ncc_binding.this) == 1
    error_message = "NCC binding should be created when network_connectivity_config_id is provided"
  }
}

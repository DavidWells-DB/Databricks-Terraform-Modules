mock_provider "databricks" {
  alias = "account"

  mock_resource "databricks_mws_workspaces" {
    defaults = {
      workspace_id             = 123456789
      workspace_url            = "https://my-serverless-workspace.cloud.databricks.com"
      workspace_status         = "RUNNING"
      workspace_status_message = ""
    }
  }

  mock_resource "databricks_mws_ncc_binding" {
    defaults = {
      id = "mock-ncc-binding-id"
    }
  }
}

variables {
  databricks_account_id = "00000000-0000-0000-0000-000000000000"
  workspace_name        = "my-serverless-workspace"
  region                = "us-east-1"
  databricks_gov_shard  = null
}

# ---------------------------------------------------------------------------
# Gov shard branching — account host local
# ---------------------------------------------------------------------------

run "commercial_shard_uses_commercial_host" {
  command = plan

  assert {
    condition     = output.databricks_account_host == "https://accounts.cloud.databricks.com"
    error_message = "Commercial shard should resolve to https://accounts.cloud.databricks.com"
  }
}

run "civilian_shard_uses_civilian_host" {
  command = plan

  variables {
    databricks_gov_shard = "civilian"
    region               = "us-gov-west-1"
  }

  assert {
    condition     = output.databricks_account_host == "https://accounts.cloud.databricks.us"
    error_message = "GovCloud civilian shard should resolve to https://accounts.cloud.databricks.us"
  }
}

run "dod_shard_uses_dod_host" {
  command = plan

  variables {
    databricks_gov_shard = "dod"
    region               = "us-gov-west-1"
  }

  assert {
    condition     = output.databricks_account_host == "https://accounts-dod.cloud.databricks.mil"
    error_message = "GovCloud DoD shard should resolve to https://accounts-dod.cloud.databricks.mil"
  }
}

# ---------------------------------------------------------------------------
# Variable validation — databricks_gov_shard
# ---------------------------------------------------------------------------

run "invalid_gov_shard_rejected" {
  command = plan

  variables {
    databricks_gov_shard = "invalid-shard"
  }

  expect_failures = [var.databricks_gov_shard]
}

# ---------------------------------------------------------------------------
# Variable validation — workspace_name
# ---------------------------------------------------------------------------

run "workspace_name_empty_rejected" {
  command = plan

  variables {
    workspace_name = ""
  }

  expect_failures = [var.workspace_name]
}

run "workspace_name_too_long_rejected" {
  command = plan

  variables {
    workspace_name = "this-workspace-name-is-way-too-long-and-exceeds-the-sixty-four-character-maximum"
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

# ---------------------------------------------------------------------------
# Variable validation — region
# ---------------------------------------------------------------------------

run "invalid_region_rejected" {
  command = plan

  variables {
    region = "not-a-region"
  }

  expect_failures = [var.region]
}

run "valid_gov_region_accepted" {
  command = plan

  variables {
    region               = "us-gov-west-1"
    databricks_gov_shard = "civilian"
  }

  assert {
    condition     = output.databricks_account_host == "https://accounts.cloud.databricks.us"
    error_message = "us-gov-west-1 with civilian shard should be accepted and resolve civilian host"
  }
}

# ---------------------------------------------------------------------------
# Resource attribute checks
# ---------------------------------------------------------------------------

run "workspace_resource_uses_serverless_compute_mode" {
  command = plan

  assert {
    condition     = databricks_mws_workspaces.this.compute_mode == "SERVERLESS"
    error_message = "compute_mode must be SERVERLESS"
  }
}

run "workspace_resource_uses_input_name" {
  command = plan

  assert {
    condition     = databricks_mws_workspaces.this.workspace_name == "my-serverless-workspace"
    error_message = "workspace_name should match the workspace_name input"
  }
}

run "workspace_resource_uses_input_region" {
  command = plan

  assert {
    condition     = databricks_mws_workspaces.this.aws_region == "us-east-1"
    error_message = "aws_region should match the region input"
  }
}

# ---------------------------------------------------------------------------
# NCC binding conditional — no NCC when not supplied
# ---------------------------------------------------------------------------

run "no_ncc_binding_without_config_id" {
  command = plan

  assert {
    condition     = length(databricks_mws_ncc_binding.this) == 0
    error_message = "databricks_mws_ncc_binding should not be created when network_connectivity_config_id is null"
  }
}

# ---------------------------------------------------------------------------
# NCC binding conditional — NCC created when supplied
# ---------------------------------------------------------------------------

run "ncc_binding_created_with_config_id" {
  command = plan

  variables {
    network_connectivity_config_id = "mock-ncc-id-abc123"
  }

  assert {
    condition     = length(databricks_mws_ncc_binding.this) == 1
    error_message = "databricks_mws_ncc_binding should be created when network_connectivity_config_id is set"
  }

  assert {
    condition     = databricks_mws_ncc_binding.this[0].network_connectivity_config_id == "mock-ncc-id-abc123"
    error_message = "NCC binding should reference the provided network_connectivity_config_id"
  }
}

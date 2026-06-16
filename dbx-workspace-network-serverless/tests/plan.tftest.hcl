mock_provider "databricks" {
  alias = "account"
}

mock_provider "databricks" {
  alias = "workspace"
}

variables {
  workspace_id                   = 1234567890123456
  network_connectivity_config_id = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
  private_endpoint_rules         = []
  network_policy_id              = null
}

# --- NCC binding ---

run "ncc_binding_uses_correct_ids" {
  command = plan

  assert {
    condition     = databricks_mws_ncc_binding.this.network_connectivity_config_id == "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
    error_message = "NCC binding should use the network_connectivity_config_id input"
  }

  assert {
    condition     = databricks_mws_ncc_binding.this.workspace_id == 1234567890123456
    error_message = "NCC binding should use the workspace_id input"
  }
}

# --- Private endpoint rules ---

run "no_pe_rules_creates_no_rule_resources" {
  command = plan

  # Verify that with an empty list the for_each produces no resources.
  assert {
    condition     = length(databricks_mws_ncc_private_endpoint_rule.this) == 0
    error_message = "No PE rule resources should be planned when private_endpoint_rules is empty"
  }
}

run "pe_rules_create_one_resource_per_entry" {
  command = plan

  variables {
    private_endpoint_rules = [
      {
        key              = "s3-east"
        endpoint_service = "com.amazonaws.us-east-1.s3"
        resource_names   = ["my-bucket"]
        enabled          = true
      },
      {
        key              = "s3-west"
        endpoint_service = "com.amazonaws.us-west-2.s3"
        resource_names   = ["my-other-bucket"]
        enabled          = true
      },
    ]
  }

  assert {
    condition     = length(databricks_mws_ncc_private_endpoint_rule.this) == 2
    error_message = "Exactly two PE rule resources should be planned for two entries"
  }
}

run "pe_rule_aws_attributes_set_correctly" {
  command = plan

  variables {
    private_endpoint_rules = [
      {
        key              = "s3-east"
        endpoint_service = "com.amazonaws.us-east-1.s3"
        resource_names   = ["my-bucket"]
        enabled          = true
      },
    ]
  }

  assert {
    condition     = databricks_mws_ncc_private_endpoint_rule.this["s3-east"].endpoint_service == "com.amazonaws.us-east-1.s3"
    error_message = "PE rule endpoint_service should match the input"
  }

  assert {
    condition     = databricks_mws_ncc_private_endpoint_rule.this["s3-east"].network_connectivity_config_id == "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
    error_message = "PE rule should reference the module-level network_connectivity_config_id"
  }
}

# --- Conditional workspace_network_option ---

run "network_policy_null_creates_no_workspace_network_option" {
  command = plan

  assert {
    condition     = length(databricks_workspace_network_option.this) == 0
    error_message = "databricks_workspace_network_option should not be created when network_policy_id is null"
  }
}

run "network_policy_provided_creates_workspace_network_option" {
  command = plan

  variables {
    network_policy_id = "default-policy"
  }

  assert {
    condition     = length(databricks_workspace_network_option.this) == 1
    error_message = "databricks_workspace_network_option should be created when network_policy_id is provided"
  }

  assert {
    condition     = databricks_workspace_network_option.this[0].network_policy_id == "default-policy"
    error_message = "workspace_network_option.network_policy_id should match the input"
  }
}

# --- Variable validations ---

run "invalid_ncc_id_not_a_uuid_rejected" {
  command = plan

  variables {
    network_connectivity_config_id = "not-a-uuid"
  }

  expect_failures = [var.network_connectivity_config_id]
}

run "invalid_ncc_id_empty_rejected" {
  command = plan

  variables {
    network_connectivity_config_id = ""
  }

  expect_failures = [var.network_connectivity_config_id]
}

run "duplicate_pe_rule_keys_rejected" {
  command = plan

  variables {
    private_endpoint_rules = [
      {
        key              = "duplicate-key"
        endpoint_service = "com.amazonaws.us-east-1.s3"
      },
      {
        key              = "duplicate-key"
        endpoint_service = "com.amazonaws.us-west-2.s3"
      },
    ]
  }

  expect_failures = [var.private_endpoint_rules]
}

mock_provider "databricks" {
  alias = "account"
}

mock_provider "time" {}

variables {
  workspace_id      = 1234567890123456
  network_policy_id = "np-abc123"
}

# --- Binding wiring ---

run "binding_uses_correct_ids" {
  command = plan

  assert {
    condition     = databricks_workspace_network_option.this.workspace_id == 1234567890123456
    error_message = "workspace_network_option should use the workspace_id input"
  }

  assert {
    condition     = databricks_workspace_network_option.this.network_policy_id == "np-abc123"
    error_message = "workspace_network_option should use the network_policy_id input"
  }

  assert {
    condition     = output.binding_id == "1234567890123456|np-abc123"
    error_message = "binding_id should be the composite <workspace_id>|<network_policy_id>"
  }
}

run "default_policy_accepted" {
  command = plan

  variables {
    network_policy_id = "default-policy"
  }

  assert {
    condition     = databricks_workspace_network_option.this.network_policy_id == "default-policy"
    error_message = "network_policy_id should accept the account default \"default-policy\""
  }
}

# --- Destroy-ordering guard (E12) ---

run "unbind_settle_uses_default_duration" {
  command = plan

  assert {
    condition     = time_sleep.unbind_settle.destroy_duration == "30s"
    error_message = "unbind_settle should default to a 30s destroy delay"
  }

  assert {
    condition     = time_sleep.unbind_settle.triggers["network_policy_id"] == "np-abc123"
    error_message = "unbind_settle should trigger on network_policy_id so it depends on the policy"
  }
}

run "unbind_settle_duration_overridable" {
  command = plan

  variables {
    unbind_settle_duration = "1m"
  }

  assert {
    condition     = time_sleep.unbind_settle.destroy_duration == "1m"
    error_message = "unbind_settle_duration should be overridable"
  }
}

# --- Variable validations ---

run "empty_network_policy_id_rejected" {
  command = plan

  variables {
    network_policy_id = ""
  }

  expect_failures = [var.network_policy_id]
}

run "invalid_settle_duration_rejected" {
  command = plan

  variables {
    unbind_settle_duration = "30 seconds"
  }

  expect_failures = [var.unbind_settle_duration]
}

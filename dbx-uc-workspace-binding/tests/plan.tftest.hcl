mock_provider "databricks" {
  alias = "workspace"

  mock_resource "databricks_workspace_binding" {
    defaults = {
      id = "binding-0123456789"
    }
  }
}

variables {
  bindings = {
    "finance-to-analytics" = {
      workspace_id   = 123456789012345
      securable_name = "finance"
    }
  }
}

run "one_binding_created_with_defaults" {
  command = plan

  assert {
    condition     = length(databricks_workspace_binding.this) == 1
    error_message = "One binding per map entry"
  }

  assert {
    condition     = databricks_workspace_binding.this["finance-to-analytics"].securable_type == "catalog"
    error_message = "securable_type must default to catalog"
  }

  assert {
    condition     = databricks_workspace_binding.this["finance-to-analytics"].binding_type == "BINDING_TYPE_READ_WRITE"
    error_message = "binding_type must default to read-write"
  }
}

run "multiple_bindings_keyed_independently" {
  command = plan

  variables {
    bindings = {
      "a-to-ws1" = {
        workspace_id   = 111
        securable_name = "a"
      }
      "a-to-ws2" = {
        workspace_id   = 222
        securable_name = "a"
        binding_type   = "BINDING_TYPE_READ_ONLY"
      }
      "b-to-ws1" = {
        workspace_id   = 111
        securable_name = "b"
        securable_type = "external_location"
      }
    }
  }

  assert {
    condition     = length(databricks_workspace_binding.this) == 3
    error_message = "The same securable CAN bind many workspaces and one workspace many securables — keys make each entry independent"
  }
}

run "invalid_binding_type_rejected" {
  command = plan

  variables {
    bindings = {
      "bad" = {
        workspace_id   = 111
        securable_name = "a"
        binding_type   = "READ_SOMETIMES"
      }
    }
  }

  expect_failures = [var.bindings]
}

run "invalid_securable_type_rejected" {
  command = plan

  variables {
    bindings = {
      "bad" = {
        workspace_id   = 111
        securable_name = "a"
        securable_type = "dashboard"
      }
    }
  }

  expect_failures = [var.bindings]
}

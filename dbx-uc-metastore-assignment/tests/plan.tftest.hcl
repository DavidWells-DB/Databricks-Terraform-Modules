mock_provider "databricks" {
  alias = "account"
}

mock_provider "databricks" {
  alias = "workspace"
}

variables {
  metastore_id = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
  workspace_ids = {
    prod = "123456789012345"
    dev  = "234567890123456"
  }
  default_catalog_name = null
}

run "assignments_created_for_each_workspace" {
  command = plan

  assert {
    condition     = databricks_metastore_assignment.this["prod"].metastore_id == "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
    error_message = "prod assignment should reference the metastore_id input"
  }

  assert {
    condition     = databricks_metastore_assignment.this["dev"].metastore_id == "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
    error_message = "dev assignment should reference the metastore_id input"
  }

  assert {
    # workspace_id is stored as a number by the provider; compare via tostring to avoid type mismatch
    condition     = tostring(databricks_metastore_assignment.this["prod"].workspace_id) == "123456789012345"
    error_message = "prod assignment workspace_id should match workspace_ids[\"prod\"]"
  }

  assert {
    condition     = tostring(databricks_metastore_assignment.this["dev"].workspace_id) == "234567890123456"
    error_message = "dev assignment workspace_id should match workspace_ids[\"dev\"]"
  }
}

run "default_namespace_setting_skipped_when_null" {
  command = plan

  assert {
    condition     = length(databricks_default_namespace_setting.this) == 0
    error_message = "databricks_default_namespace_setting should not be created when default_catalog_name is null"
  }
}

run "default_namespace_setting_created_when_set" {
  command = plan

  variables {
    default_catalog_name = "main"
  }

  assert {
    condition     = length(databricks_default_namespace_setting.this) == 1
    error_message = "databricks_default_namespace_setting should be created when default_catalog_name is set"
  }

  assert {
    condition     = databricks_default_namespace_setting.this[0].namespace[0].value == "main"
    error_message = "databricks_default_namespace_setting namespace value should match default_catalog_name"
  }
}

run "invalid_metastore_id_rejected" {
  command = plan

  variables {
    metastore_id = "not-a-uuid"
  }

  expect_failures = [var.metastore_id]
}

run "empty_workspace_ids_rejected" {
  command = plan

  variables {
    workspace_ids = {}
  }

  expect_failures = [var.workspace_ids]
}

run "non_numeric_workspace_id_rejected" {
  command = plan

  variables {
    workspace_ids = {
      bad = "not-a-number"
    }
  }

  expect_failures = [var.workspace_ids]
}

run "default_catalog_name_with_leading_whitespace_rejected" {
  command = plan

  variables {
    default_catalog_name = " main"
  }

  expect_failures = [var.default_catalog_name]
}

run "default_catalog_name_empty_string_rejected" {
  command = plan

  variables {
    default_catalog_name = ""
  }

  expect_failures = [var.default_catalog_name]
}

run "output_metastore_id_echoes_input" {
  command = plan

  assert {
    condition     = output.metastore_id == "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
    error_message = "output.metastore_id should echo the metastore_id input"
  }
}

run "output_default_catalog_name_null_when_unset" {
  command = plan

  assert {
    condition     = output.default_catalog_name == null
    error_message = "output.default_catalog_name should be null when default_catalog_name is not set"
  }
}

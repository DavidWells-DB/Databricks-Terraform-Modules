mock_provider "databricks" {
  alias = "account"
}

mock_provider "time" {}

variables {
  workspace_id = 1234567890
  assignments = {
    data_engineering = {
      principal_id = 111111111
      roles        = ["USER"]
    }
    workspace_admins = {
      principal_id = 222222222
      roles        = ["ADMIN"]
    }
  }
}

run "happy_path_creates_two_assignments" {
  command = plan

  assert {
    condition     = length(databricks_mws_permission_assignment.this) == 2
    error_message = "Expected two permission assignments when two entries are provided"
  }
}

run "assignment_ids_output_keyed_consistently" {
  command = plan

  assert {
    condition     = contains(keys(output.assignment_ids), "data_engineering")
    error_message = "assignment_ids output should contain key 'data_engineering'"
  }

  assert {
    condition     = contains(keys(output.assignment_ids), "workspace_admins")
    error_message = "assignment_ids output should contain key 'workspace_admins'"
  }
}

run "workspace_id_set_on_resources" {
  command = plan

  assert {
    condition     = databricks_mws_permission_assignment.this["data_engineering"].workspace_id == 1234567890
    error_message = "workspace_id on assignment should match the module input"
  }
}

run "user_role_set_correctly" {
  command = plan

  assert {
    condition     = contains(databricks_mws_permission_assignment.this["data_engineering"].permissions, "USER")
    error_message = "data_engineering assignment should have USER role"
  }
}

run "admin_role_set_correctly" {
  command = plan

  assert {
    condition     = contains(databricks_mws_permission_assignment.this["workspace_admins"].permissions, "ADMIN")
    error_message = "workspace_admins assignment should have ADMIN role"
  }
}

run "empty_roles_rejected" {
  command = plan

  variables {
    assignments = {
      bad_entry = {
        principal_id = 333333333
        roles        = []
      }
    }
  }

  expect_failures = [var.assignments]
}

run "invalid_role_value_rejected" {
  command = plan

  variables {
    assignments = {
      bad_role = {
        principal_id = 444444444
        roles        = ["VIEWER"]
      }
    }
  }

  expect_failures = [var.assignments]
}

run "mixed_valid_and_invalid_roles_rejected" {
  command = plan

  variables {
    assignments = {
      mixed = {
        principal_id = 555555555
        roles        = ["USER", "SUPERADMIN"]
      }
    }
  }

  expect_failures = [var.assignments]
}

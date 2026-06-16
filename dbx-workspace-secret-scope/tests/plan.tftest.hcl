mock_provider "databricks" {
  alias = "workspace"
}

variables {
  scopes = {
    "app-secrets" = {
      initial_manage_principal = "users"
    }
    "infra-secrets" = {}
  }
}

run "scope_names_match_keys" {
  command = plan

  assert {
    condition     = contains(tolist(output.scope_names), "app-secrets")
    error_message = "scope_names output should include \"app-secrets\""
  }

  assert {
    condition     = contains(tolist(output.scope_names), "infra-secrets")
    error_message = "scope_names output should include \"infra-secrets\""
  }
}

run "all_scopes_created_via_for_each" {
  command = plan

  assert {
    condition     = length(output.scope_names) == 2
    error_message = "Expected exactly 2 scopes to be created"
  }
}

run "resource_name_matches_map_key" {
  command = plan

  assert {
    condition     = databricks_secret_scope.this["app-secrets"].name == "app-secrets"
    error_message = "Resource name should equal the map key"
  }
}

run "initial_manage_principal_passed_through" {
  command = plan

  assert {
    condition     = databricks_secret_scope.this["app-secrets"].initial_manage_principal == "users"
    error_message = "initial_manage_principal should be \"users\" for app-secrets"
  }
}

run "initial_manage_principal_null_when_omitted" {
  command = plan

  assert {
    condition     = databricks_secret_scope.this["infra-secrets"].initial_manage_principal == null
    error_message = "initial_manage_principal should be null when not set"
  }
}

run "scope_name_too_long_rejected" {
  command = plan

  variables {
    scopes = {
      "this-scope-name-is-way-too-long-and-exceeds-the-databricks-maximum-of-one-hundred-and-twenty-eight-characters-which-is-the-limit-x" = {}
    }
  }

  expect_failures = [var.scopes]
}

run "scope_name_invalid_chars_rejected" {
  command = plan

  variables {
    scopes = {
      "invalid scope name with spaces" = {}
    }
  }

  expect_failures = [var.scopes]
}

run "scope_name_at_sign_rejected" {
  command = plan

  variables {
    scopes = {
      "invalid@scope" = {}
    }
  }

  expect_failures = [var.scopes]
}

run "initial_manage_principal_invalid_value_rejected" {
  command = plan

  variables {
    scopes = {
      "test-scope" = {
        initial_manage_principal = "admins"
      }
    }
  }

  expect_failures = [var.scopes]
}

run "single_scope_with_valid_name_passes" {
  command = plan

  variables {
    scopes = {
      "my.valid_scope-name" = {}
    }
  }

  assert {
    condition     = contains(tolist(output.scope_names), "my.valid_scope-name")
    error_message = "Scope name with dots, underscores, and hyphens should be accepted"
  }
}

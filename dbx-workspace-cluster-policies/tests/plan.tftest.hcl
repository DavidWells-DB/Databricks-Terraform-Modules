mock_provider "databricks" {
  alias = "workspace"
}

# ---------------------------------------------------------------------------
# Default variables: one custom-definition policy, no assignments
# ---------------------------------------------------------------------------
variables {
  policies = {
    "test-policy" = {
      definition = "{\"autotermination_minutes\":{\"type\":\"fixed\",\"value\":20}}"
    }
  }
  policy_assignments = {}
}

# ---------------------------------------------------------------------------
# Resource attribute: custom-definition policy is planned with correct name
# ---------------------------------------------------------------------------
run "definition_policy_planned_with_name" {
  command = plan

  assert {
    condition     = databricks_cluster_policy.this["test-policy"].name == "test-policy"
    error_message = "Cluster policy name should match the map key"
  }
}

run "definition_policy_planned_with_definition" {
  command = plan

  assert {
    condition     = databricks_cluster_policy.this["test-policy"].definition == "{\"autotermination_minutes\":{\"type\":\"fixed\",\"value\":20}}"
    error_message = "Cluster policy definition should match the input definition string"
  }
}

# ---------------------------------------------------------------------------
# Resource attribute: policy-family policy is planned with correct family ID
# ---------------------------------------------------------------------------
run "policy_family_policy_planned_with_family_id" {
  command = plan

  variables {
    policies = {
      "personal-compute" = {
        policy_family_id = "personal-vm"
      }
    }
  }

  assert {
    condition     = databricks_cluster_policy.this["personal-compute"].policy_family_id == "personal-vm"
    error_message = "Cluster policy should have the provided policy_family_id"
  }
}

# ---------------------------------------------------------------------------
# Resource attribute: policy-family override is passed through
# ---------------------------------------------------------------------------
run "policy_family_overrides_passed_through" {
  command = plan

  variables {
    policies = {
      "personal-compute" = {
        policy_family_id                   = "personal-vm"
        policy_family_definition_overrides = "{\"autotermination_minutes\":{\"type\":\"fixed\",\"value\":120}}"
      }
    }
  }

  assert {
    condition     = databricks_cluster_policy.this["personal-compute"].policy_family_definition_overrides == "{\"autotermination_minutes\":{\"type\":\"fixed\",\"value\":120}}"
    error_message = "policy_family_definition_overrides should be passed through to the resource"
  }
}

# ---------------------------------------------------------------------------
# Permissions: policy with assignments produces a databricks_permissions resource
# ---------------------------------------------------------------------------
run "permissions_created_for_assigned_policy" {
  command = plan

  variables {
    policy_assignments = {
      "test-policy" = {
        access_controls = [
          { group_name = "data-engineers" }
        ]
      }
    }
  }

  assert {
    condition     = length(databricks_permissions.this) == 1
    error_message = "Expected one databricks_permissions resource for the assigned policy"
  }
}

# ---------------------------------------------------------------------------
# Permissions: policy with no assignments produces no permissions resource
# ---------------------------------------------------------------------------
run "no_permissions_when_no_assignments" {
  command = plan

  variables {
    policy_assignments = {}
  }

  assert {
    condition     = length(databricks_permissions.this) == 0
    error_message = "Expected no databricks_permissions resources when policy_assignments is empty"
  }
}

# ---------------------------------------------------------------------------
# Validation: both definition and policy_family_id set is rejected
# ---------------------------------------------------------------------------
run "both_definition_and_family_id_rejected" {
  command = plan

  variables {
    policies = {
      "bad-policy" = {
        definition       = "{}"
        policy_family_id = "personal-vm"
      }
    }
  }

  expect_failures = [var.policies]
}

# ---------------------------------------------------------------------------
# Validation: neither definition nor policy_family_id set is rejected
# ---------------------------------------------------------------------------
run "neither_definition_nor_family_id_rejected" {
  command = plan

  variables {
    policies = {
      "bad-policy" = {
        description = "missing both definition and family id"
      }
    }
  }

  expect_failures = [var.policies]
}

# ---------------------------------------------------------------------------
# Validation: policy_family_definition_overrides without policy_family_id rejected
# ---------------------------------------------------------------------------
run "overrides_without_family_id_rejected" {
  command = plan

  variables {
    policies = {
      "bad-policy" = {
        definition                         = "{}"
        policy_family_definition_overrides = "{\"autotermination_minutes\":{\"type\":\"fixed\",\"value\":20}}"
      }
    }
  }

  expect_failures = [var.policies]
}

# ---------------------------------------------------------------------------
# Validation: max_clusters_per_user = 0 is rejected
# ---------------------------------------------------------------------------
run "max_clusters_per_user_zero_rejected" {
  command = plan

  variables {
    policies = {
      "bad-policy" = {
        definition            = "{}"
        max_clusters_per_user = 0
      }
    }
  }

  expect_failures = [var.policies]
}

# ---------------------------------------------------------------------------
# Validation: max_clusters_per_user positive value passes
# ---------------------------------------------------------------------------
run "max_clusters_per_user_positive_passes" {
  command = plan

  variables {
    policies = {
      "throttled-policy" = {
        definition            = "{}"
        max_clusters_per_user = 3
      }
    }
  }

  assert {
    condition     = databricks_cluster_policy.this["throttled-policy"].max_clusters_per_user == 3
    error_message = "max_clusters_per_user should be set to the provided positive integer"
  }
}

# ---------------------------------------------------------------------------
# Validation: policy name (map key) empty string rejected
# ---------------------------------------------------------------------------
run "empty_policy_name_rejected" {
  command = plan

  variables {
    policies = {
      "" = {
        definition = "{}"
      }
    }
  }

  expect_failures = [var.policies]
}

# ---------------------------------------------------------------------------
# Validation: policy name over 100 characters rejected
# ---------------------------------------------------------------------------
run "policy_name_over_100_chars_rejected" {
  command = plan

  variables {
    policies = {
      "this-policy-name-is-way-too-long-and-exceeds-the-databricks-one-hundred-character-limit-xxxxxxxxxxxxxxxx" = {
        definition = "{}"
      }
    }
  }

  expect_failures = [var.policies]
}

# ---------------------------------------------------------------------------
# Validation: access_control with multiple principal selectors rejected
# ---------------------------------------------------------------------------
run "access_control_multiple_principals_rejected" {
  command = plan

  variables {
    policy_assignments = {
      "test-policy" = {
        access_controls = [
          {
            group_name = "data-engineers"
            user_name  = "alice@example.com"
          }
        ]
      }
    }
  }

  expect_failures = [var.policy_assignments]
}

# ---------------------------------------------------------------------------
# Validation: access_control with no principal selector rejected
# ---------------------------------------------------------------------------
run "access_control_no_principal_rejected" {
  command = plan

  variables {
    policy_assignments = {
      "test-policy" = {
        access_controls = [
          {}
        ]
      }
    }
  }

  expect_failures = [var.policy_assignments]
}

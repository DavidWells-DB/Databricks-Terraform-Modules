mock_provider "databricks" {
  alias = "workspace"
}

variables {
  metastore_id = "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
  catalogs = {
    analytics = {
      comment        = "Analytics catalog"
      storage_root   = null
      isolation_mode = "OPEN"
      properties     = { team = "analytics" }
      grants = [
        {
          principal  = "analysts"
          privileges = ["USE_CATALOG", "SELECT"]
        }
      ]
    }
    sandbox = {
      comment        = null
      storage_root   = null
      isolation_mode = "OPEN"
      properties     = {}
      grants         = []
    }
  }
}

# ---------------------------------------------------------------------------
# Resource attribute assertions
# ---------------------------------------------------------------------------

run "catalog_resources_planned_with_correct_metastore" {
  command = plan

  assert {
    condition     = databricks_catalog.this["analytics"].metastore_id == "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
    error_message = "analytics catalog should reference the provided metastore_id"
  }

  assert {
    condition     = databricks_catalog.this["sandbox"].metastore_id == "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
    error_message = "sandbox catalog should reference the provided metastore_id"
  }
}

run "catalog_name_matches_map_key" {
  command = plan

  assert {
    condition     = databricks_catalog.this["analytics"].name == "analytics"
    error_message = "catalog name should match the map key"
  }
}

run "catalog_comment_set_correctly" {
  command = plan

  assert {
    condition     = databricks_catalog.this["analytics"].comment == "Analytics catalog"
    error_message = "catalog comment should match the input value"
  }
}

run "catalog_isolation_mode_set_correctly" {
  command = plan

  assert {
    condition     = databricks_catalog.this["analytics"].isolation_mode == "OPEN"
    error_message = "catalog isolation_mode should be OPEN"
  }
}

run "isolated_mode_catalog_is_planned" {
  command = plan

  variables {
    catalogs = {
      restricted = {
        comment        = "Isolated catalog"
        storage_root   = null
        isolation_mode = "ISOLATED"
        properties     = {}
        grants         = []
      }
    }
  }

  assert {
    condition     = databricks_catalog.this["restricted"].isolation_mode == "ISOLATED"
    error_message = "catalog isolation_mode should be ISOLATED"
  }
}

# ---------------------------------------------------------------------------
# Conditional grants logic
# ---------------------------------------------------------------------------

run "grants_created_only_for_catalogs_with_nonempty_grants" {
  command = plan

  # analytics has grants; sandbox does not. Only analytics should produce a databricks_grants resource.
  assert {
    condition     = length(databricks_grants.this) == 1
    error_message = "expected exactly one databricks_grants resource (only analytics has grants)"
  }
}

run "grants_not_created_for_empty_grants_list" {
  command = plan

  variables {
    catalogs = {
      nogrants = {
        comment        = null
        storage_root   = null
        isolation_mode = "OPEN"
        properties     = {}
        grants         = []
      }
    }
  }

  assert {
    condition     = length(databricks_grants.this) == 0
    error_message = "no databricks_grants resource should be created when grants list is empty"
  }
}

run "grants_created_when_grants_list_is_nonempty" {
  command = plan

  variables {
    catalogs = {
      withgrants = {
        comment        = null
        storage_root   = null
        isolation_mode = "OPEN"
        properties     = {}
        grants = [
          {
            principal  = "data-engineers"
            privileges = ["USE_CATALOG", "CREATE_SCHEMA"]
          }
        ]
      }
    }
  }

  assert {
    condition     = length(databricks_grants.this) == 1
    error_message = "databricks_grants resource should be created when grants list is non-empty"
  }
}

# ---------------------------------------------------------------------------
# Variable validation: metastore_id
# ---------------------------------------------------------------------------

run "invalid_metastore_id_not_uuid_rejected" {
  command = plan

  variables {
    metastore_id = "not-a-valid-uuid"
  }

  expect_failures = [var.metastore_id]
}

run "metastore_id_uppercase_uuid_rejected" {
  command = plan

  variables {
    metastore_id = "A1B2C3D4-E5F6-7890-ABCD-EF1234567890"
  }

  expect_failures = [var.metastore_id]
}

# ---------------------------------------------------------------------------
# Variable validation: catalog names
# ---------------------------------------------------------------------------

run "catalog_name_starting_with_digit_rejected" {
  command = plan

  variables {
    catalogs = {
      "1invalid" = {
        comment        = null
        storage_root   = null
        isolation_mode = "OPEN"
        properties     = {}
        grants         = []
      }
    }
  }

  expect_failures = [var.catalogs]
}

run "catalog_name_with_uppercase_rejected" {
  command = plan

  variables {
    catalogs = {
      "InvalidName" = {
        comment        = null
        storage_root   = null
        isolation_mode = "OPEN"
        properties     = {}
        grants         = []
      }
    }
  }

  expect_failures = [var.catalogs]
}

run "catalog_name_with_hyphen_rejected" {
  command = plan

  variables {
    catalogs = {
      "invalid-name" = {
        comment        = null
        storage_root   = null
        isolation_mode = "OPEN"
        properties     = {}
        grants         = []
      }
    }
  }

  expect_failures = [var.catalogs]
}

# ---------------------------------------------------------------------------
# Variable validation: isolation_mode
# ---------------------------------------------------------------------------

run "invalid_isolation_mode_rejected" {
  command = plan

  variables {
    catalogs = {
      badmode = {
        comment        = null
        storage_root   = null
        isolation_mode = "RESTRICTED"
        properties     = {}
        grants         = []
      }
    }
  }

  expect_failures = [var.catalogs]
}

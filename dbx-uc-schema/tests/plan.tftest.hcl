mock_provider "databricks" {
  alias = "workspace"
}

variables {
  catalog_name = "analytics"
  schemas = {
    raw = {
      comment      = "Raw ingestion schema"
      storage_root = null
      properties   = { team = "data-engineering" }
      grants = [
        {
          principal  = "data-engineers"
          privileges = ["USE_SCHEMA", "CREATE_TABLE"]
        }
      ]
    }
    curated = {
      comment      = null
      storage_root = null
      properties   = {}
      grants       = []
    }
  }
}

# ---------------------------------------------------------------------------
# Resource attribute assertions
# ---------------------------------------------------------------------------

run "schema_resources_planned_with_correct_catalog" {
  command = plan

  assert {
    condition     = databricks_schema.this["raw"].catalog_name == "analytics"
    error_message = "raw schema should reference the provided catalog_name"
  }

  assert {
    condition     = databricks_schema.this["curated"].catalog_name == "analytics"
    error_message = "curated schema should reference the provided catalog_name"
  }
}

run "schema_name_matches_map_key" {
  command = plan

  assert {
    condition     = databricks_schema.this["raw"].name == "raw"
    error_message = "schema name should match the map key"
  }
}

run "schema_comment_set_correctly" {
  command = plan

  assert {
    condition     = databricks_schema.this["raw"].comment == "Raw ingestion schema"
    error_message = "schema comment should match the input value"
  }
}

run "schema_with_storage_root_planned" {
  command = plan

  variables {
    schemas = {
      external_schema = {
        comment      = "Schema with custom storage"
        storage_root = "s3://my-bucket/schemas/external"
        properties   = {}
        grants       = []
      }
    }
  }

  assert {
    condition     = databricks_schema.this["external_schema"].storage_root == "s3://my-bucket/schemas/external"
    error_message = "schema storage_root should match the input value"
  }
}

# ---------------------------------------------------------------------------
# Conditional grants logic
# ---------------------------------------------------------------------------

run "grants_created_only_for_schemas_with_nonempty_grants" {
  command = plan

  # raw has grants; curated does not. Only raw should produce a databricks_grants resource.
  assert {
    condition     = length(databricks_grants.this) == 1
    error_message = "expected exactly one databricks_grants resource (only raw has grants)"
  }
}

run "grants_not_created_for_empty_grants_list" {
  command = plan

  variables {
    schemas = {
      nogrants = {
        comment      = null
        storage_root = null
        properties   = {}
        grants       = []
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
    schemas = {
      withgrants = {
        comment      = null
        storage_root = null
        properties   = {}
        grants = [
          {
            principal  = "data-engineers"
            privileges = ["USE_SCHEMA", "CREATE_TABLE"]
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
# Variable validation: catalog_name
# ---------------------------------------------------------------------------

run "invalid_catalog_name_starting_with_digit_rejected" {
  command = plan

  variables {
    catalog_name = "1invalid"
  }

  expect_failures = [var.catalog_name]
}

run "invalid_catalog_name_with_hyphen_rejected" {
  command = plan

  variables {
    catalog_name = "my-catalog"
  }

  expect_failures = [var.catalog_name]
}

run "invalid_catalog_name_with_uppercase_rejected" {
  command = plan

  variables {
    catalog_name = "MyCatalog"
  }

  expect_failures = [var.catalog_name]
}

# ---------------------------------------------------------------------------
# Variable validation: schema names
# ---------------------------------------------------------------------------

run "schema_name_starting_with_digit_rejected" {
  command = plan

  variables {
    schemas = {
      "1invalid" = {
        comment      = null
        storage_root = null
        properties   = {}
        grants       = []
      }
    }
  }

  expect_failures = [var.schemas]
}

run "schema_name_with_uppercase_rejected" {
  command = plan

  variables {
    schemas = {
      "InvalidName" = {
        comment      = null
        storage_root = null
        properties   = {}
        grants       = []
      }
    }
  }

  expect_failures = [var.schemas]
}

run "schema_name_with_hyphen_rejected" {
  command = plan

  variables {
    schemas = {
      "invalid-name" = {
        comment      = null
        storage_root = null
        properties   = {}
        grants       = []
      }
    }
  }

  expect_failures = [var.schemas]
}

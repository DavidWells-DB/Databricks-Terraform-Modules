mock_provider "databricks" {
  alias = "workspace"
}

# Default variables used by all runs unless overridden.
variables {
  locations = {
    raw_data = {
      url                   = "s3://my-bucket/raw"
      storage_credential_id = "cred-abc123"
    }
  }
}

# --- Resource attribute checks ---

run "external_location_name_matches_map_key" {
  command = plan

  assert {
    condition     = databricks_external_location.this["raw_data"].name == "raw_data"
    error_message = "External location name should match the locations map key"
  }
}

run "external_location_url_matches_input" {
  command = plan

  assert {
    condition     = databricks_external_location.this["raw_data"].url == "s3://my-bucket/raw"
    error_message = "External location url should match the url field in the locations map"
  }
}

run "external_location_credential_matches_input" {
  command = plan

  assert {
    condition     = databricks_external_location.this["raw_data"].credential_name == "cred-abc123"
    error_message = "External location credential_name should match the storage_credential_id input"
  }
}

run "read_only_defaults_to_false" {
  command = plan

  assert {
    condition     = databricks_external_location.this["raw_data"].read_only == false
    error_message = "read_only should default to false when not set"
  }
}

run "skip_validation_defaults_to_false" {
  command = plan

  assert {
    condition     = databricks_external_location.this["raw_data"].skip_validation == false
    error_message = "skip_validation should default to false when not set"
  }
}

run "read_only_can_be_set_true" {
  command = plan

  variables {
    locations = {
      archive = {
        url                   = "s3://my-bucket/archive"
        storage_credential_id = "cred-abc123"
        read_only             = true
      }
    }
  }

  assert {
    condition     = databricks_external_location.this["archive"].read_only == true
    error_message = "read_only should be true when explicitly set"
  }
}

run "skip_validation_can_be_set_true" {
  command = plan

  variables {
    locations = {
      raw_data = {
        url                   = "s3://my-bucket/raw"
        storage_credential_id = "cred-abc123"
        skip_validation       = true
      }
    }
  }

  assert {
    condition     = databricks_external_location.this["raw_data"].skip_validation == true
    error_message = "skip_validation should be true when explicitly set"
  }
}

# --- Grants inclusion / omission ---

run "no_grants_resource_when_grants_empty" {
  command = plan

  # locations map key has no grants — databricks_grants.this should be empty
  assert {
    condition     = length(databricks_grants.this) == 0
    error_message = "databricks_grants.this should be empty when no location has grants"
  }
}

run "grants_resource_created_when_grants_provided" {
  command = plan

  variables {
    locations = {
      raw_data = {
        url                   = "s3://my-bucket/raw"
        storage_credential_id = "cred-abc123"
        grants = {
          "data-engineers" = ["READ_FILES", "WRITE_FILES"]
        }
      }
    }
  }

  assert {
    condition     = length(databricks_grants.this) == 1
    error_message = "databricks_grants.this should have one entry when grants are specified for a location"
  }
}

run "multiple_locations_planned_correctly" {
  command = plan

  variables {
    locations = {
      raw_data = {
        url                   = "s3://my-bucket/raw"
        storage_credential_id = "cred-abc123"
      }
      curated = {
        url                   = "gs://my-gcs-bucket/curated"
        storage_credential_id = "cred-gcs456"
      }
    }
  }

  assert {
    condition     = length(databricks_external_location.this) == 2
    error_message = "Two external locations should be planned when two locations are specified"
  }
}

# --- Variable validation ---

run "invalid_url_scheme_rejected" {
  command = plan

  variables {
    locations = {
      bad_loc = {
        url                   = "https://my-bucket/raw"
        storage_credential_id = "cred-abc123"
      }
    }
  }

  expect_failures = [var.locations]
}

run "invalid_location_name_with_spaces_rejected" {
  command = plan

  variables {
    locations = {
      "invalid name" = {
        url                   = "s3://my-bucket/raw"
        storage_credential_id = "cred-abc123"
      }
    }
  }

  expect_failures = [var.locations]
}

run "invalid_location_name_with_special_chars_rejected" {
  command = plan

  variables {
    locations = {
      "invalid!name" = {
        url                   = "s3://my-bucket/raw"
        storage_credential_id = "cred-abc123"
      }
    }
  }

  expect_failures = [var.locations]
}

run "empty_storage_credential_id_rejected" {
  command = plan

  variables {
    locations = {
      raw_data = {
        url                   = "s3://my-bucket/raw"
        storage_credential_id = ""
      }
    }
  }

  expect_failures = [var.locations]
}

run "abfss_url_accepted" {
  command = plan

  variables {
    locations = {
      azure_loc = {
        url                   = "abfss://container@account.dfs.core.windows.net/path"
        storage_credential_id = "cred-azure789"
      }
    }
  }

  assert {
    condition     = databricks_external_location.this["azure_loc"].url == "abfss://container@account.dfs.core.windows.net/path"
    error_message = "abfss:// URL should be accepted and passed through correctly"
  }
}

run "gcs_url_accepted" {
  command = plan

  variables {
    locations = {
      gcs_loc = {
        url                   = "gs://my-gcs-bucket/path"
        storage_credential_id = "cred-gcs456"
      }
    }
  }

  assert {
    condition     = databricks_external_location.this["gcs_loc"].url == "gs://my-gcs-bucket/path"
    error_message = "gs:// URL should be accepted and passed through correctly"
  }
}

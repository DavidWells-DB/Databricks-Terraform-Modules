mock_provider "databricks" {
  alias = "account"

  override_resource {
    target = databricks_mws_network_connectivity_config.this
    values = {
      network_connectivity_config_id = "mock-ncc-id-00000000"
      creation_time                  = 1700000000000
      updated_time                   = 1700000000000
    }
  }
}

variables {
  region = "us-east-1"
  name   = "test-ncc"
}

# --- Resource attribute checks ---

run "resource_uses_input_name" {
  command = plan

  assert {
    condition     = databricks_mws_network_connectivity_config.this.name == "test-ncc"
    error_message = "NCC name should match the name input"
  }
}

run "resource_uses_input_region" {
  command = plan

  assert {
    condition     = databricks_mws_network_connectivity_config.this.region == "us-east-1"
    error_message = "NCC region should match the region input"
  }
}

# --- region validation ---

run "valid_region_us_east_1_accepted" {
  command = plan

  variables {
    region = "us-east-1"
  }

  assert {
    condition     = databricks_mws_network_connectivity_config.this.region == "us-east-1"
    error_message = "us-east-1 should be accepted as a valid region"
  }
}

run "valid_region_eu_west_2_accepted" {
  command = plan

  variables {
    region = "eu-west-2"
  }

  assert {
    condition     = databricks_mws_network_connectivity_config.this.region == "eu-west-2"
    error_message = "eu-west-2 should be accepted as a valid region"
  }
}

run "valid_region_us_gov_west_1_accepted" {
  command = plan

  variables {
    region = "us-gov-west-1"
  }

  assert {
    condition     = databricks_mws_network_connectivity_config.this.region == "us-gov-west-1"
    error_message = "us-gov-west-1 should be accepted as a valid GovCloud region"
  }
}

run "invalid_region_rejected" {
  command = plan

  variables {
    region = "not-a-region"
  }

  expect_failures = [var.region]
}

# --- name validation ---

run "name_min_length_accepted" {
  command = plan

  variables {
    name = "abc"
  }

  assert {
    condition     = databricks_mws_network_connectivity_config.this.name == "abc"
    error_message = "3-character name should be accepted (minimum length)"
  }
}

run "name_max_length_accepted" {
  command = plan

  variables {
    name = "abcdefghij-ABCDEFGHIJ_12345678"
  }

  assert {
    condition     = databricks_mws_network_connectivity_config.this.name == "abcdefghij-ABCDEFGHIJ_12345678"
    error_message = "30-character name should be accepted (maximum length)"
  }
}

run "name_too_short_rejected" {
  command = plan

  variables {
    name = "ab"
  }

  expect_failures = [var.name]
}

run "name_too_long_rejected" {
  command = plan

  variables {
    name = "this-name-is-way-too-long-exceeds-30"
  }

  expect_failures = [var.name]
}

run "name_invalid_chars_rejected" {
  command = plan

  variables {
    name = "invalid name with spaces"
  }

  expect_failures = [var.name]
}

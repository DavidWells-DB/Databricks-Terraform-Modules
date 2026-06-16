mock_provider "databricks" {
  alias = "account"
}

variables {
  databricks_account_id = "00000000-0000-0000-0000-000000000000"
  name                  = "ncc-eastus-test"
  region                = "eastus"
}

# ---------------------------------------------------------------------------
# NCC resource attributes
# ---------------------------------------------------------------------------

run "ncc_resource_uses_input_name" {
  command = plan

  assert {
    condition     = databricks_mws_network_connectivity_config.this.name == "ncc-eastus-test"
    error_message = "NCC name should match the name input"
  }
}

run "ncc_resource_uses_input_region" {
  command = plan

  assert {
    condition     = databricks_mws_network_connectivity_config.this.region == "eastus"
    error_message = "NCC region should match the region input"
  }
}

run "ncc_resource_uses_account_id" {
  command = plan

  assert {
    condition     = databricks_mws_network_connectivity_config.this.account_id == "00000000-0000-0000-0000-000000000000"
    error_message = "NCC account_id should match the databricks_account_id input"
  }
}

# ---------------------------------------------------------------------------
# Conditional network policy — no policy when allowed_internet_destinations is null
# ---------------------------------------------------------------------------

run "no_network_policy_when_destinations_null" {
  command = plan

  # allowed_internet_destinations defaults to null
  assert {
    condition     = length(databricks_account_network_policy.this) == 0
    error_message = "No network policy resource should be created when allowed_internet_destinations is null"
  }
}

run "no_network_policy_output_is_null" {
  command = plan

  assert {
    condition     = output.network_policy_id == null
    error_message = "network_policy_id output should be null when no policy is created"
  }
}

# ---------------------------------------------------------------------------
# Conditional network policy — policy created when destinations are provided
# ---------------------------------------------------------------------------

run "network_policy_created_when_destinations_set" {
  command = plan

  variables {
    network_policy_id = "test-policy"
    allowed_internet_destinations = [
      {
        destination               = "example.com"
        internet_destination_type = "DNS_NAME"
      }
    ]
  }

  assert {
    condition     = length(databricks_account_network_policy.this) == 1
    error_message = "A network policy resource should be created when allowed_internet_destinations is set"
  }
}

# ---------------------------------------------------------------------------
# Variable validation: name constraints
# ---------------------------------------------------------------------------

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
    name = "this-name-is-way-too-long-for-ncc"
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

run "name_at_minimum_length_accepted" {
  command = plan

  variables {
    name = "abc"
  }

  assert {
    condition     = databricks_mws_network_connectivity_config.this.name == "abc"
    error_message = "A 3-character name should be accepted"
  }
}

run "name_at_maximum_length_accepted" {
  command = plan

  variables {
    name = "ncc-012345678901234567890123"
  }

  assert {
    condition     = databricks_mws_network_connectivity_config.this.name == "ncc-012345678901234567890123"
    error_message = "A 30-character name should be accepted"
  }
}

# ---------------------------------------------------------------------------
# Variable validation: internet_destination_type
# ---------------------------------------------------------------------------

run "invalid_internet_destination_type_rejected" {
  command = plan

  variables {
    network_policy_id = "test-policy"
    allowed_internet_destinations = [
      {
        destination               = "example.com"
        internet_destination_type = "IP_ADDRESS"
      }
    ]
  }

  expect_failures = [var.allowed_internet_destinations]
}

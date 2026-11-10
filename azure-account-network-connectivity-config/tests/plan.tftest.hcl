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

# ---------------------------------------------------------------------------
# Conditional network policy — policy created when destinations are provided
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Variable validation: name constraints
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Variable validation: internet_destination_type
# ---------------------------------------------------------------------------

# --- policy inputs guarded (single-owner consolidation, v0.2.0) -----------
run "allowed_internet_destinations_rejected" {
  command = plan

  variables {
    allowed_internet_destinations = [{
      destination               = "pypi.org"
      internet_destination_type = "DNS_NAME"
    }]
  }

  expect_failures = [var.allowed_internet_destinations]
}

run "network_policy_id_rejected" {
  command = plan

  variables {
    network_policy_id = "some-policy"
  }

  expect_failures = [var.network_policy_id]
}

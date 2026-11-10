mock_provider "databricks" {
  alias = "account"

  mock_resource "databricks_mws_networks" {
    defaults = {
      network_id = "network-0123456789"
    }
  }
}

variables {
  databricks_account_id = "743862e4-fdac-4504-a9cc-2d69bd1605e8"
  vpc_id                = "vpc-0123456789abcdef0"
  private_subnet_ids    = ["subnet-aaa", "subnet-bbb"]
  security_group_ids    = ["sg-0123456789abcdef0"]
  network_name          = "test-network"
}

run "only_base_config_when_privatelink_disabled" {
  command = plan

  assert {
    condition     = length(databricks_mws_networks.this) == 1
    error_message = "Only the base registration should exist with enable_privatelink = false"
  }

  assert {
    condition     = length(databricks_mws_networks.this["base"].vpc_endpoints) == 0
    error_message = "Base registration must not carry vpc_endpoints"
  }
}

run "databricks_network_id_is_base_when_privatelink_disabled" {
  command = apply

  assert {
    condition     = output.databricks_network_id == "network-0123456789" && length(output.network_ids) == 1
    error_message = "The active network must be base; network_ids only carries base"
  }
}

run "privatelink_config_added_and_base_retained_when_enabled" {
  command = plan

  variables {
    enable_privatelink = true
  }

  assert {
    condition     = length(databricks_mws_networks.this) == 2
    error_message = "Both base and privatelink registrations must exist when enable_privatelink = true (base RETAINED, never replaced)"
  }

  assert {
    condition     = databricks_mws_networks.this["privatelink"].network_name == "test-network-privatelink"
    error_message = "The PrivateLink config name must be derived as <network_name>-privatelink"
  }
}

run "privatelink_key_is_driven_by_bool_not_endpoint_values" {
  command = plan

  variables {
    enable_privatelink = true
    vpc_endpoint_ids = {
      relay_id    = null
      rest_api_id = null
    }
  }

  # The invariant: the KEY SET (2 configs) comes from the bool — with a non-null endpoint
  # object whose ids are null, the PL registration carries one vpc_endpoints block with
  # EMPTY endpoint lists (the values, not the key set, come from the object).
  assert {
    condition     = length(databricks_mws_networks.this) == 2
    error_message = "enable_privatelink (not endpoint values) drives the key set"
  }

  assert {
    condition     = databricks_mws_networks.this["privatelink"].network_name == "test-network-privatelink"
    error_message = "The PL variant name must derive from network_name regardless of endpoint values"
  }
}

run "vpc_endpoints_land_only_on_privatelink_registration" {
  command = plan

  variables {
    enable_privatelink = true
    vpc_endpoint_ids = {
      relay_id    = "vpce-relay-123"
      rest_api_id = "vpce-rest-456"
    }
  }

  assert {
    condition     = length(databricks_mws_networks.this["base"].vpc_endpoints) == 0 && length(databricks_mws_networks.this["privatelink"].vpc_endpoints) == 1
    error_message = "Endpoint IDs belong ONLY to the privatelink registration"
  }
}

run "network_name_too_long_rejected" {
  command = plan

  variables {
    network_name = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" # 90
  }

  expect_failures = [var.network_name]
}

run "too_few_subnets_rejected" {
  command = plan

  variables {
    private_subnet_ids = ["subnet-aaa"]
  }

  expect_failures = [var.private_subnet_ids]
}

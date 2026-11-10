mock_provider "databricks" {
  alias = "account"

  mock_resource "databricks_mws_network_connectivity_config" {
    defaults = {
      network_connectivity_config_id = "01234567-89ab-cdef-0123-456789abcdef"
      name                          = "ncc-test"
    }
  }

  mock_resource "databricks_account_network_policy" {
    defaults = {
      network_policy_id = "policy-test"
      account_id        = "00000000-0000-0000-0000-000000000000"
    }
  }
}

# NOTE: child-module RESOURCES are not assertable from plan tests (mock outputs only) —
# assert through the composition's outputs, the module-output oracle.
variables {
  databricks_account_id = "743862e4-fdac-4504-a9cc-2d69bd1605e8"
  region               = "eastus"
  ncc_name             = "ncc-test"
}

run "ncc_id_passes_through_by_default" {
  command = apply

  assert {
    condition     = output.network_connectivity_config_id == "01234567-89ab-cdef-0123-456789abcdef"
    error_message = "The NCC ID must flow through from the owner module (default: no policy)"
  }

  assert {
    condition     = output.network_policy_id == null
    error_message = "network_policy_id output must be null when create_policy = false"
  }
}

run "policy_id_passes_through_when_enabled" {
  command = apply

  variables {
    create_policy                 = true
    policy_name                   = "egress"
    allowed_internet_destinations = [
      {
        destination               = "pypi.org"
        internet_destination_type = "DNS_NAME"
      }
    ]
  }

  assert {
    # mock defaults only fill UNSET attributes: network_policy_id is set from policy_name in
    # config, so the flow-through value here IS the configured name.
    condition     = output.network_policy_id == "egress"
    error_message = "network_policy_id must flow through from the policy owner module when create_policy = true"
  }
}

run "ncc_name_validation_rejected" {
  command = plan

  # The validation lives in the NCC owner module's variable — address it there.
  variables {
    ncc_name = "bad name!"
  }

  expect_failures = [var.ncc_name]
}

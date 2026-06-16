mock_provider "databricks" {
  alias = "account"
}

variables {
  policy_name = "test-policy"
  egress_mode = "ALLOW_LIST"
}

run "policy_name_uses_input" {
  command = plan

  assert {
    condition     = databricks_account_network_policy.this.network_policy_id == "test-policy"
    error_message = "Network policy name should match the policy_name input"
  }
}

run "egress_mode_uses_input" {
  command = plan

  assert {
    condition     = databricks_account_network_policy.this.egress.network_access.restriction_mode == "ALLOW_LIST"
    error_message = "Egress mode should match the egress_mode input"
  }
}

run "unrestricted_mode_accepted" {
  command = plan

  variables {
    egress_mode = "UNRESTRICTED"
  }

  assert {
    condition     = databricks_account_network_policy.this.egress.network_access.restriction_mode == "UNRESTRICTED"
    error_message = "UNRESTRICTED egress mode should be accepted"
  }
}

run "invalid_egress_mode_rejected" {
  command = plan

  variables {
    egress_mode = "INVALID_MODE"
  }

  expect_failures = [var.egress_mode]
}

run "policy_name_too_long_rejected" {
  command = plan

  variables {
    policy_name = "this-policy-name-is-way-too-long-and-exceeds-the-thirty-two-character-limit"
  }

  expect_failures = [var.policy_name]
}

run "policy_name_empty_rejected" {
  command = plan

  variables {
    policy_name = ""
  }

  expect_failures = [var.policy_name]
}

run "policy_name_invalid_chars_rejected" {
  command = plan

  variables {
    policy_name = "invalid_policy_name_with_underscores"
  }

  expect_failures = [var.policy_name]
}

run "policy_name_with_spaces_rejected" {
  command = plan

  variables {
    policy_name = "invalid policy name"
  }

  expect_failures = [var.policy_name]
}

run "allowed_internet_destinations_empty_by_default" {
  command = plan

  assert {
    condition     = length(databricks_account_network_policy.this.egress.network_access.allowed_internet_destinations) == 0
    error_message = "allowed_internet_destinations should be empty by default"
  }
}

run "allowed_storage_destinations_empty_by_default" {
  command = plan

  assert {
    condition     = length(databricks_account_network_policy.this.egress.network_access.allowed_storage_destinations) == 0
    error_message = "allowed_storage_destinations should be empty by default"
  }
}

run "allowed_internet_destinations_can_be_set" {
  command = plan

  variables {
    allowed_internet_destinations = [
      {
        destination               = "10.0.0.0/8"
        internet_destination_type = "CIDR"
      },
      {
        destination               = "example.com"
        internet_destination_type = "FQDN"
      }
    ]
  }

  assert {
    condition     = length(databricks_account_network_policy.this.egress.network_access.allowed_internet_destinations) == 2
    error_message = "Should allow multiple internet destinations"
  }
}

run "allowed_storage_destinations_can_be_set" {
  command = plan

  variables {
    allowed_storage_destinations = [
      {
        bucket_name              = "my-s3-bucket"
        azure_storage_account    = null
        azure_storage_service    = null
        region                   = "us-west-2"
        storage_destination_type = null
      },
      {
        bucket_name              = null
        azure_storage_account    = "myazurestorage"
        azure_storage_service    = "blob"
        region                   = null
        storage_destination_type = null
      }
    ]
  }

  assert {
    condition     = length(databricks_account_network_policy.this.egress.network_access.allowed_storage_destinations) == 2
    error_message = "Should allow multiple storage destinations"
  }
}

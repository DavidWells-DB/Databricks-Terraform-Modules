mock_provider "aws" {}

mock_provider "databricks" {
  alias = "account"
}

variables {
  databricks_gov_shard               = null
  vpc_id                             = "vpc-0123456789abcdef0"
  privatelink_subnet_ids             = ["subnet-0123456789abcdef0"]
  region                             = "us-east-1"
  private_access_settings_name       = "test-pas"
  workspace_vpc_endpoint_name        = "test-workspace-vpce"
  relay_vpc_endpoint_name            = "test-relay-vpce"
  security_group_name                = "test-privatelink-sg"
  security_group_ingress_cidr_blocks = ["10.0.0.0/16"]
}

# ---------------------------------------------------------------------------
# GovCloud shard branching — workspace service attachment URIs
# ---------------------------------------------------------------------------

run "commercial_workspace_service_name" {
  command = plan

  assert {
    condition     = output.workspace_service_name == "com.amazonaws.vpce.us-east-1.vpce-svc-09143d1e626de2f04"
    error_message = "Commercial us-east-1 workspace service name does not match expected value"
  }
}

run "commercial_relay_service_name" {
  command = plan

  assert {
    condition     = output.relay_service_name == "com.amazonaws.vpce.us-east-1.vpce-svc-00018a8c3ff62ffdf"
    error_message = "Commercial us-east-1 relay service name does not match expected value"
  }
}

run "civilian_shard_workspace_service_name" {
  command = plan

  variables {
    databricks_gov_shard = "civilian"
    region               = "us-gov-west-1"
  }

  assert {
    condition     = output.workspace_service_name == "com.amazonaws.vpce.us-gov-west-1.vpce-svc-0f25e28401cbc9418"
    error_message = "GovCloud civilian workspace service name does not match expected value"
  }
}

run "civilian_shard_relay_service_name" {
  command = plan

  variables {
    databricks_gov_shard = "civilian"
    region               = "us-gov-west-1"
  }

  assert {
    condition     = output.relay_service_name == "com.amazonaws.vpce.us-gov-west-1.vpce-svc-05f27abef1a1a3faa"
    error_message = "GovCloud civilian relay service name does not match expected value"
  }
}

run "dod_shard_workspace_service_name" {
  command = plan

  variables {
    databricks_gov_shard = "dod"
    region               = "us-gov-west-1"
  }

  assert {
    condition     = output.workspace_service_name == "com.amazonaws.vpce.us-gov-west-1.vpce-svc-08fddf710780b2a54"
    error_message = "GovCloud DoD workspace service name does not match expected value"
  }
}

run "dod_shard_relay_service_name" {
  command = plan

  variables {
    databricks_gov_shard = "dod"
    region               = "us-gov-west-1"
  }

  assert {
    condition     = output.relay_service_name == "com.amazonaws.vpce.us-gov-west-1.vpce-svc-05c210a2feea23ad7"
    error_message = "GovCloud DoD relay service name does not match expected value"
  }
}

run "eu_west_1_workspace_service_name" {
  command = plan

  variables {
    region = "eu-west-1"
  }

  assert {
    condition     = output.workspace_service_name == "com.amazonaws.vpce.eu-west-1.vpce-svc-0da6ebf1461278016"
    error_message = "eu-west-1 workspace service name does not match expected value"
  }
}

# ---------------------------------------------------------------------------
# Custom service attachment URI override
# ---------------------------------------------------------------------------

run "custom_workspace_uri_overrides_map" {
  command = plan

  variables {
    custom_service_attachment_uris = {
      workspace = "com.amazonaws.vpce.us-east-1.vpce-svc-custom-workspace"
      relay     = null
    }
  }

  assert {
    condition     = output.workspace_service_name == "com.amazonaws.vpce.us-east-1.vpce-svc-custom-workspace"
    error_message = "Custom workspace URI should override the built-in map"
  }
}

# ---------------------------------------------------------------------------
# enable_service_direct = false produces no service-direct resources
# ---------------------------------------------------------------------------

run "service_direct_disabled_produces_null_output" {
  command = plan

  variables {
    enable_service_direct = false
  }

  assert {
    condition     = output.service_direct_vpc_endpoint_id == null
    error_message = "service_direct_vpc_endpoint_id should be null when enable_service_direct = false"
  }

  assert {
    condition     = output.service_direct_aws_vpc_endpoint_id == null
    error_message = "service_direct_aws_vpc_endpoint_id should be null when enable_service_direct = false"
  }
}

# ---------------------------------------------------------------------------
# Variable validation — rejected inputs
# ---------------------------------------------------------------------------

run "invalid_gov_shard_rejected" {
  command = plan

  variables {
    databricks_gov_shard = "invalid-shard"
  }

  expect_failures = [var.databricks_gov_shard]
}

run "invalid_vpc_id_format_rejected" {
  command = plan

  variables {
    vpc_id = "not-a-vpc-id"
  }

  expect_failures = [var.vpc_id]
}

run "invalid_region_format_rejected" {
  command = plan

  variables {
    region = "us_east_1"
  }

  expect_failures = [var.region]
}

run "empty_privatelink_subnet_ids_rejected" {
  command = plan

  variables {
    privatelink_subnet_ids = []
  }

  expect_failures = [var.privatelink_subnet_ids]
}

run "invalid_subnet_id_format_rejected" {
  command = plan

  variables {
    privatelink_subnet_ids = ["not-a-subnet-id"]
  }

  expect_failures = [var.privatelink_subnet_ids]
}

run "invalid_private_access_level_rejected" {
  command = plan

  variables {
    private_access_level = "ALL"
  }

  expect_failures = [var.private_access_level]
}

run "empty_private_access_settings_name_rejected" {
  command = plan

  variables {
    private_access_settings_name = ""
  }

  expect_failures = [var.private_access_settings_name]
}

run "empty_security_group_name_rejected" {
  command = plan

  variables {
    security_group_name = ""
  }

  expect_failures = [var.security_group_name]
}

run "empty_security_group_ingress_cidr_blocks_rejected" {
  command = plan

  variables {
    security_group_ingress_cidr_blocks = []
  }

  expect_failures = [var.security_group_ingress_cidr_blocks]
}

# ---------------------------------------------------------------------------
# Resource attribute assertions
# ---------------------------------------------------------------------------

run "security_group_attached_to_correct_vpc" {
  command = plan

  assert {
    condition     = aws_security_group.this.vpc_id == "vpc-0123456789abcdef0"
    error_message = "Security group vpc_id should match the vpc_id input"
  }
}

run "workspace_endpoint_uses_correct_service_name" {
  command = plan

  assert {
    condition     = aws_vpc_endpoint.workspace.service_name == "com.amazonaws.vpce.us-east-1.vpce-svc-09143d1e626de2f04"
    error_message = "Workspace VPC endpoint should use the us-east-1 service attachment URI"
  }
}

run "workspace_endpoint_is_interface_type" {
  command = plan

  assert {
    condition     = aws_vpc_endpoint.workspace.vpc_endpoint_type == "Interface"
    error_message = "Workspace VPC endpoint type must be Interface"
  }
}

run "relay_endpoint_uses_correct_service_name" {
  command = plan

  assert {
    condition     = aws_vpc_endpoint.relay.service_name == "com.amazonaws.vpce.us-east-1.vpce-svc-00018a8c3ff62ffdf"
    error_message = "Relay VPC endpoint should use the us-east-1 relay service attachment URI"
  }
}

run "private_access_settings_uses_account_level" {
  command = plan

  assert {
    condition     = databricks_mws_private_access_settings.this.private_access_level == "ACCOUNT"
    error_message = "Private access level should default to ACCOUNT"
  }
}

run "private_access_settings_public_access_default_false" {
  command = plan

  assert {
    condition     = databricks_mws_private_access_settings.this.public_access_enabled == false
    error_message = "public_access_enabled should default to false"
  }
}

mock_provider "aws" {}

# Default valid variables used across most test runs.
variables {
  requester_vpc_id          = "vpc-0a1b2c3d4e5f6a7b8"
  accepter_vpc_id           = "vpc-0b2c3d4e5f6a7b8c9"
  requester_vpc_cidr        = "10.0.0.0/16"
  accepter_vpc_cidr         = "10.1.0.0/16"
  requester_route_table_ids = ["rtb-0a1b2c3d4e5f6a7b8", "rtb-0b2c3d4e5f6a7b8c9"]
  accepter_route_table_ids  = ["rtb-0c3d4e5f6a7b8c9d0"]
  accepter_account_id       = "123456789012"
  accepter_region           = "us-east-1"
  peering_name              = "test-peering"
}

# ---------------------------------------------------------------------------
# Happy-path resource attribute checks
# ---------------------------------------------------------------------------

run "peering_connection_uses_requester_vpc" {
  command = plan

  assert {
    condition     = aws_vpc_peering_connection.this.vpc_id == "vpc-0a1b2c3d4e5f6a7b8"
    error_message = "VPC peering connection should use the requester_vpc_id input"
  }
}

run "peering_connection_uses_accepter_vpc" {
  command = plan

  assert {
    condition     = aws_vpc_peering_connection.this.peer_vpc_id == "vpc-0b2c3d4e5f6a7b8c9"
    error_message = "VPC peering connection should use the accepter_vpc_id input"
  }
}

run "peering_connection_uses_accepter_account" {
  command = plan

  assert {
    condition     = aws_vpc_peering_connection.this.peer_owner_id == "123456789012"
    error_message = "VPC peering connection should use the accepter_account_id input"
  }
}

run "peering_connection_not_auto_accepted" {
  command = plan

  assert {
    condition     = aws_vpc_peering_connection.this.auto_accept == false
    error_message = "Requester-side peering connection must not auto_accept (only the accepter resource does)"
  }
}

run "peering_accepter_auto_accepts" {
  command = plan

  assert {
    condition     = aws_vpc_peering_connection_accepter.this.auto_accept == true
    error_message = "Accepter resource should have auto_accept = true"
  }
}

run "requester_routes_created_for_each_route_table" {
  command = plan

  assert {
    condition     = length(aws_route.requester_to_accepter) == 2
    error_message = "Should create one route per requester route table ID (2 provided)"
  }
}

run "accepter_routes_created_for_each_route_table" {
  command = plan

  assert {
    condition     = length(aws_route.accepter_to_requester) == 1
    error_message = "Should create one route per accepter route table ID (1 provided)"
  }
}

run "requester_route_destination_is_accepter_cidr" {
  command = plan

  assert {
    condition     = aws_route.requester_to_accepter["rtb-0a1b2c3d4e5f6a7b8"].destination_cidr_block == "10.1.0.0/16"
    error_message = "Requester route destination should be the accepter VPC CIDR"
  }
}

run "accepter_route_destination_is_requester_cidr" {
  command = plan

  assert {
    condition     = aws_route.accepter_to_requester["rtb-0c3d4e5f6a7b8c9d0"].destination_cidr_block == "10.0.0.0/16"
    error_message = "Accepter route destination should be the requester VPC CIDR"
  }
}

run "name_tag_applied_to_peering_connection" {
  command = plan

  assert {
    condition     = aws_vpc_peering_connection.this.tags["Name"] == "test-peering"
    error_message = "Peering connection should have a Name tag matching the peering_name input"
  }
}

# ---------------------------------------------------------------------------
# Variable validation: invalid VPC IDs
# ---------------------------------------------------------------------------

run "invalid_requester_vpc_id_rejected" {
  command = plan

  variables {
    requester_vpc_id = "invalid-vpc"
  }

  expect_failures = [var.requester_vpc_id]
}

run "invalid_accepter_vpc_id_rejected" {
  command = plan

  variables {
    accepter_vpc_id = "vpc_without_hex"
  }

  expect_failures = [var.accepter_vpc_id]
}

# ---------------------------------------------------------------------------
# Variable validation: invalid route table IDs
# ---------------------------------------------------------------------------

run "invalid_requester_route_table_id_rejected" {
  command = plan

  variables {
    requester_route_table_ids = ["rtb-valid", "not-a-route-table"]
  }

  expect_failures = [var.requester_route_table_ids]
}

run "empty_requester_route_table_ids_rejected" {
  command = plan

  variables {
    requester_route_table_ids = []
  }

  expect_failures = [var.requester_route_table_ids]
}

run "empty_accepter_route_table_ids_rejected" {
  command = plan

  variables {
    accepter_route_table_ids = []
  }

  expect_failures = [var.accepter_route_table_ids]
}

# ---------------------------------------------------------------------------
# Variable validation: invalid CIDR blocks
# ---------------------------------------------------------------------------

run "invalid_requester_vpc_cidr_rejected" {
  command = plan

  variables {
    requester_vpc_cidr = "not-a-cidr"
  }

  expect_failures = [var.requester_vpc_cidr]
}

run "invalid_accepter_vpc_cidr_rejected" {
  command = plan

  variables {
    accepter_vpc_cidr = "256.0.0.0/8"
  }

  expect_failures = [var.accepter_vpc_cidr]
}

# ---------------------------------------------------------------------------
# Variable validation: invalid accepter account ID
# ---------------------------------------------------------------------------

run "accepter_account_id_too_short_rejected" {
  command = plan

  variables {
    accepter_account_id = "12345678901"
  }

  expect_failures = [var.accepter_account_id]
}

run "accepter_account_id_non_numeric_rejected" {
  command = plan

  variables {
    accepter_account_id = "1234567890ab"
  }

  expect_failures = [var.accepter_account_id]
}

# ---------------------------------------------------------------------------
# Variable validation: invalid accepter region
# ---------------------------------------------------------------------------

run "invalid_accepter_region_rejected" {
  command = plan

  variables {
    accepter_region = "us-east"
  }

  expect_failures = [var.accepter_region]
}

run "accepter_region_plain_string_rejected" {
  command = plan

  variables {
    accepter_region = "useast1"
  }

  expect_failures = [var.accepter_region]
}

# ---------------------------------------------------------------------------
# Variable validation: peering_name bounds
# ---------------------------------------------------------------------------

run "empty_peering_name_rejected" {
  command = plan

  variables {
    peering_name = ""
  }

  expect_failures = [var.peering_name]
}

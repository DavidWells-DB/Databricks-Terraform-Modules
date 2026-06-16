mock_provider "aws" {}

variables {
  vpc_id                  = "vpc-0a1b2c3d4e5f67890"
  public_subnet_ids       = ["subnet-0a1b2c3d4e5f67890", "subnet-0b2c3d4e5f678901"]
  private_route_table_ids = ["rtb-0a1b2c3d4e5f67890", "rtb-0b2c3d4e5f678901"]
  nat_gateway_count       = 1
}

run "igw_attached_to_vpc" {
  command = plan

  assert {
    condition     = aws_internet_gateway.this.vpc_id == "vpc-0a1b2c3d4e5f67890"
    error_message = "Internet Gateway vpc_id should match the vpc_id input"
  }
}

run "eip_count_matches_nat_gateway_count" {
  command = plan

  assert {
    condition     = length(aws_eip.nat) == 1
    error_message = "Number of EIPs should equal nat_gateway_count"
  }
}

run "nat_gateway_count_matches_input" {
  command = plan

  assert {
    condition     = length(aws_nat_gateway.this) == 1
    error_message = "Number of NAT Gateways should equal nat_gateway_count"
  }
}

run "nat_gateway_placed_in_first_public_subnet" {
  command = plan

  assert {
    condition     = aws_nat_gateway.this[0].subnet_id == "subnet-0a1b2c3d4e5f67890"
    error_message = "NAT Gateway should be placed in the first public subnet"
  }
}

run "private_routes_count_matches_route_table_count" {
  command = plan

  assert {
    condition     = length(aws_route.private_nat) == 2
    error_message = "Number of private routes should equal the number of private_route_table_ids"
  }
}

run "private_route_destination_is_all_traffic" {
  command = plan

  assert {
    condition     = aws_route.private_nat[0].destination_cidr_block == "0.0.0.0/0"
    error_message = "Private NAT route destination should be 0.0.0.0/0"
  }
}

run "multi_nat_gateway_count" {
  command = plan

  variables {
    nat_gateway_count = 2
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 2
    error_message = "Two NAT Gateways should be created when nat_gateway_count = 2"
  }

  assert {
    condition     = length(aws_eip.nat) == 2
    error_message = "Two EIPs should be created when nat_gateway_count = 2"
  }
}

run "multi_nat_second_gateway_in_second_subnet" {
  command = plan

  variables {
    nat_gateway_count = 2
  }

  assert {
    condition     = aws_nat_gateway.this[1].subnet_id == "subnet-0b2c3d4e5f678901"
    error_message = "Second NAT Gateway should be placed in the second public subnet"
  }
}

run "invalid_vpc_id_rejected" {
  command = plan

  variables {
    vpc_id = "invalid-vpc-id"
  }

  expect_failures = [var.vpc_id]
}

run "invalid_public_subnet_id_rejected" {
  command = plan

  variables {
    public_subnet_ids = ["not-a-subnet-id"]
  }

  expect_failures = [var.public_subnet_ids]
}

run "invalid_private_route_table_id_rejected" {
  command = plan

  variables {
    private_route_table_ids = ["not-a-rtb-id"]
  }

  expect_failures = [var.private_route_table_ids]
}

run "empty_public_subnet_ids_rejected" {
  command = plan

  variables {
    public_subnet_ids = []
  }

  expect_failures = [var.public_subnet_ids]
}

run "empty_private_route_table_ids_rejected" {
  command = plan

  variables {
    private_route_table_ids = []
  }

  expect_failures = [var.private_route_table_ids]
}

run "zero_nat_gateway_count_rejected" {
  command = plan

  variables {
    nat_gateway_count = 0
  }

  expect_failures = [var.nat_gateway_count]
}

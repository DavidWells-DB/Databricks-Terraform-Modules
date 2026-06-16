mock_provider "aws" {}

mock_provider "databricks" {
  alias = "account"
}

variables {
  databricks_account_id = "00000000-0000-0000-0000-000000000000"
  databricks_gov_shard  = null
  resource_prefix       = "test"
  network_name          = "test-network"
  vpc_cidr              = "10.0.0.0/16"
  azs                   = ["us-east-1a", "us-east-1b"]
  private_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
}

# ── Variable validation ────────────────────────────────────────────────────────

run "invalid_gov_shard_rejected" {
  command = plan

  variables {
    databricks_gov_shard = "invalid-shard"
  }

  expect_failures = [var.databricks_gov_shard]
}

run "civilian_gov_shard_accepted" {
  command = plan

  variables {
    databricks_gov_shard = "civilian"
    azs                  = ["us-gov-west-1a", "us-gov-west-1b"]
  }

  assert {
    condition     = aws_vpc.this.cidr_block == "10.0.0.0/16"
    error_message = "VPC CIDR should match input for civilian shard"
  }
}

run "dod_gov_shard_accepted" {
  command = plan

  variables {
    databricks_gov_shard = "dod"
    azs                  = ["us-gov-east-1a", "us-gov-east-1b"]
  }

  assert {
    condition     = aws_vpc.this.cidr_block == "10.0.0.0/16"
    error_message = "VPC CIDR should match input for dod shard"
  }
}

run "resource_prefix_too_long_rejected" {
  command = plan

  variables {
    resource_prefix = "this-prefix-is-way-too-long-and-exceeds-the-thirty-two-character-limit"
  }

  expect_failures = [var.resource_prefix]
}

run "resource_prefix_invalid_chars_rejected" {
  command = plan

  variables {
    resource_prefix = "invalid prefix with spaces"
  }

  expect_failures = [var.resource_prefix]
}

run "resource_prefix_empty_rejected" {
  command = plan

  variables {
    resource_prefix = ""
  }

  expect_failures = [var.resource_prefix]
}

run "invalid_vpc_cidr_rejected" {
  command = plan

  variables {
    vpc_cidr = "not-a-cidr"
  }

  expect_failures = [var.vpc_cidr]
}

run "private_subnet_cidrs_too_few_rejected" {
  command = plan

  variables {
    private_subnet_cidrs = ["10.0.1.0/24"]
  }

  expect_failures = [var.private_subnet_cidrs]
}

run "private_subnet_cidrs_invalid_cidr_rejected" {
  command = plan

  variables {
    private_subnet_cidrs = ["not-a-cidr", "10.0.2.0/24"]
  }

  expect_failures = [var.private_subnet_cidrs]
}

run "public_subnet_cidrs_invalid_cidr_rejected" {
  command = plan

  variables {
    public_subnet_cidrs = ["bad-cidr"]
  }

  expect_failures = [var.public_subnet_cidrs]
}

run "privatelink_subnet_cidrs_invalid_cidr_rejected" {
  command = plan

  variables {
    privatelink_subnet_cidrs = ["bad-cidr"]
  }

  expect_failures = [var.privatelink_subnet_cidrs]
}

run "azs_too_few_rejected" {
  command = plan

  variables {
    azs = ["us-east-1a"]
  }

  expect_failures = [var.azs]
}

run "azs_invalid_format_rejected" {
  command = plan

  variables {
    azs = ["not-an-az", "also-not-an-az"]
  }

  expect_failures = [var.azs]
}

run "network_name_empty_rejected" {
  command = plan

  variables {
    network_name = ""
  }

  expect_failures = [var.network_name]
}

run "network_name_invalid_chars_rejected" {
  command = plan

  variables {
    network_name = "invalid name with spaces"
  }

  expect_failures = [var.network_name]
}

# ── Resource attribute checks ─────────────────────────────────────────────────

run "vpc_has_correct_cidr" {
  command = plan

  assert {
    condition     = aws_vpc.this.cidr_block == "10.0.0.0/16"
    error_message = "VPC CIDR block should match the vpc_cidr input"
  }
}

run "vpc_has_dns_enabled" {
  command = plan

  assert {
    condition     = aws_vpc.this.enable_dns_hostnames == true
    error_message = "VPC should have DNS hostnames enabled (required for Databricks)"
  }

  assert {
    condition     = aws_vpc.this.enable_dns_support == true
    error_message = "VPC should have DNS support enabled (required for Databricks)"
  }
}

run "security_group_named_with_prefix" {
  command = plan

  assert {
    condition     = aws_security_group.this.name == "test-databricks"
    error_message = "Security group name should be <resource_prefix>-databricks"
  }
}

run "two_private_subnets_created" {
  command = plan

  assert {
    condition     = length(aws_subnet.private) == 2
    error_message = "Should create exactly 2 private subnets (one per entry in private_subnet_cidrs)"
  }
}

run "no_public_subnets_when_omitted" {
  command = plan

  assert {
    condition     = length(aws_subnet.public) == 0
    error_message = "Should create 0 public subnets when public_subnet_cidrs is empty"
  }
}

run "public_subnets_created_when_specified" {
  command = plan

  variables {
    public_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]
  }

  assert {
    condition     = length(aws_subnet.public) == 2
    error_message = "Should create 2 public subnets when public_subnet_cidrs has 2 entries"
  }
}

run "no_privatelink_subnets_when_omitted" {
  command = plan

  assert {
    condition     = length(aws_subnet.privatelink) == 0
    error_message = "Should create 0 PrivateLink subnets when privatelink_subnet_cidrs is empty"
  }
}

run "privatelink_subnets_created_when_specified" {
  command = plan

  variables {
    privatelink_subnet_cidrs = ["10.0.201.0/24", "10.0.202.0/24"]
  }

  assert {
    condition     = length(aws_subnet.privatelink) == 2
    error_message = "Should create 2 PrivateLink subnets when privatelink_subnet_cidrs has 2 entries"
  }
}

run "private_route_tables_match_subnet_count" {
  command = plan

  assert {
    condition     = length(aws_route_table.private) == 2
    error_message = "Should create one route table per private subnet"
  }
}

# ── PrivateLink conditional logic ─────────────────────────────────────────────

run "no_vpc_endpoints_block_when_null" {
  command = plan

  # vpc_endpoint_ids defaults to null — no vpc_endpoints block should be included.
  assert {
    condition     = length(databricks_mws_networks.this.vpc_endpoints) == 0
    error_message = "vpc_endpoints block should be absent when vpc_endpoint_ids is null"
  }
}

run "vpc_endpoints_block_present_when_provided" {
  command = plan

  variables {
    vpc_endpoint_ids = {
      rest_api_id = "vpce-0123456789abcdef0"
      relay_id    = "vpce-0123456789abcdef1"
    }
  }

  assert {
    condition     = length(databricks_mws_networks.this.vpc_endpoints) == 1
    error_message = "vpc_endpoints block should be present when vpc_endpoint_ids is provided"
  }
}

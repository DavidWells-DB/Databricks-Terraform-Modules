mock_provider "aws" {
  mock_resource "aws_vpc" {
    defaults = {
      id = "vpc-0123456789abcdef0"
    }
  }
  mock_resource "aws_subnet" {
    defaults = {
      id = "subnet-0123456789abcdef0"
    }
  }
  mock_resource "aws_route_table" {
    defaults = {
      id = "rtb-0123456789abcdef0"
    }
  }
  mock_resource "aws_security_group" {
    defaults = {
      id = "sg-0123456789abcdef0"
    }
  }
  mock_resource "aws_route_table_association" {
    defaults = {
      id = "rtassoc-0123456789abcdef0"
    }
  }
}

mock_provider "databricks" {
  alias = "account"

  mock_resource "databricks_mws_networks" {
    defaults = {
      network_id = "network-0123456789"
    }
  }
}

# The subnet mock default gives every instance the SAME id — databricks_mws_networks
# takes subnet_ids as a SET, so identical ids collapse to one item and fail its
# minimum-2 schema rule. Give the two private subnets distinct ids.
override_resource {
  target = module.vpc.aws_subnet.private["test-ws-private-0"]
  values = { id = "subnet-aaa" }
}
override_resource {
  target = module.vpc.aws_subnet.private["test-ws-private-1"]
  values = { id = "subnet-bbb" }
}

variables {
  databricks_account_id = "743862e4-fdac-4504-a9cc-2d69bd1605e8"
  resource_prefix       = "test-ws"
  vpc_cidr              = "10.0.0.0/16"
  private_subnet_cidrs  = ["10.0.32.0/20", "10.0.48.0/20"]
  azs                   = ["us-east-1a", "us-east-1b"]
  network_name          = "test-network"
}

# --- variable validations (the composed surface is unchanged) -------------------

run "invalid_gov_shard_rejected" {
  command = plan

  variables {
    databricks_gov_shard = "not-a-shard"
  }

  expect_failures = [var.databricks_gov_shard]
}

run "civilian_gov_shard_accepted" {
  command = plan

  variables {
    databricks_gov_shard = "civilian"
  }

  assert {
    condition     = output.databricks_account_host == "https://accounts.cloud.databricks.us"
    error_message = "The civilian shard host must be derived for the output"
  }
}

run "dod_gov_shard_accepted" {
  command = plan

  variables {
    databricks_gov_shard = "dod"
  }

  assert {
    condition     = output.databricks_account_host == "https://accounts-dod.cloud.databricks.mil"
    error_message = "The dod shard host must be derived for the output"
  }
}

run "resource_prefix_too_long_rejected" {
  command = plan

  variables {
    resource_prefix = "a-very-long-prefix-that-exceeds-the-limit-of-thirty-two-characters"
  }

  expect_failures = [var.resource_prefix]
}

run "invalid_vpc_cidr_rejected" {
  command = plan

  variables {
    vpc_cidr = "300.1.1.1/16"
  }

  expect_failures = [var.vpc_cidr]
}

run "private_subnet_cidrs_too_few_rejected" {
  command = plan

  variables {
    private_subnet_cidrs = ["10.0.32.0/20"]
  }

  expect_failures = [var.private_subnet_cidrs]
}

run "azs_too_few_rejected" {
  command = plan

  variables {
    azs = ["us-east-1a"]
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
    network_name = "bad name!"
  }

  expect_failures = [var.network_name]
}

# --- composition outputs (children are not resource-assertable; outputs are the oracle) ---

run "cloud_side_outputs_flow_through" {
  command = apply

  assert {
    condition     = output.vpc_id == "vpc-0123456789abcdef0" && output.vpc_cidr == "10.0.0.0/16"
    error_message = "The VPC outputs must flow through from the cloud child"
  }

  assert {
    condition     = length(output.private_subnet_ids) == 2 && length(output.private_route_table_ids) == 2
    error_message = "Two private subnets + route tables must exist (per private_subnet_cidrs)"
  }

  assert {
    condition     = output.security_group_id == "sg-0123456789abcdef0"
    error_message = "The SG id must flow through"
  }
}

run "no_public_or_privatelink_subnets_when_omitted" {
  command = apply

  assert {
    condition     = length(output.public_subnet_ids) == 0 && length(output.privatelink_subnet_ids) == 0
    error_message = "No public/PL subnets when their CIDR lists are empty"
  }
}

run "public_and_privatelink_subnets_when_specified" {
  command = apply

  variables {
    public_subnet_cidrs      = ["10.0.0.0/24"]
    privatelink_subnet_cidrs = ["10.0.2.0/24"]
  }

  assert {
    condition     = length(output.public_subnet_ids) == 1 && length(output.privatelink_subnet_ids) == 1
    error_message = "Public and PL subnets must follow their CIDR lists"
  }
}

run "registration_defaults_to_base_only" {
  command = apply

  assert {
    condition     = output.databricks_network_id == "network-0123456789" && length(output.network_ids) == 1
    error_message = "Default: one (base) registration; databricks_network_id = base"
  }
}

run "privatelink_adds_registration_and_retains_base" {
  command = apply

  variables {
    enable_privatelink = true
  }

  assert {
    condition     = length(output.network_ids) == 2
    error_message = "enable_privatelink must ADD the privatelink registration while base is RETAINED (the live-verified in-place cutover semantics)"
  }

  assert {
    condition     = can(lookup(output.network_ids, "base")) && can(lookup(output.network_ids, "privatelink"))
    error_message = "network_ids must carry both roles after the PL cutover"
  }
}

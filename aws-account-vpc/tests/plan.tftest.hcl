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

variables {
  resource_prefix      = "test-ws"
  vpc_cidr             = "10.0.0.0/16"
  private_subnet_cidrs = ["10.0.32.0/20", "10.0.48.0/20"]
  azs                  = ["us-east-1a", "us-east-1b"]
}

run "vpc_has_correct_cidr" {
  command = plan

  assert {
    condition     = aws_vpc.this.cidr_block == "10.0.0.0/16"
    error_message = "VPC CIDR should match the vpc_cidr input"
  }
}

run "vpc_has_dns_enabled" {
  command = plan

  assert {
    condition     = aws_vpc.this.enable_dns_hostnames == true && aws_vpc.this.enable_dns_support == true
    error_message = "VPC DNS hostnames and support should both be enabled"
  }
}

run "two_private_subnets_created" {
  command = plan

  assert {
    condition     = length(aws_subnet.private) == 2
    error_message = "Two private subnets should be created, one per private_subnet_cidrs entry"
  }
}

run "no_public_or_privatelink_subnets_when_omitted" {
  command = plan

  assert {
    condition     = length(aws_subnet.public) == 0 && length(aws_subnet.privatelink) == 0
    error_message = "No public or PrivateLink subnets should be created when their CIDR lists are empty"
  }
}

run "public_subnets_created_when_specified" {
  command = plan

  variables {
    public_subnet_cidrs = ["10.0.0.0/24"]
  }

  assert {
    condition     = length(aws_subnet.public) == 1
    error_message = "Public subnets should follow public_subnet_cidrs"
  }
}

run "private_route_tables_match_subnet_count" {
  command = plan

  assert {
    condition     = length(aws_route_table.private) == 2 && length(aws_route_table_association.private) == 2
    error_message = "One route table + association per private subnet"
  }
}

run "security_group_named_with_prefix" {
  command = plan

  assert {
    condition     = aws_security_group.this.name == "test-ws-databricks"
    error_message = "SG name should be <resource_prefix>-databricks"
  }
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

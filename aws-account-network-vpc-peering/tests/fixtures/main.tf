# Test fixtures: two minimal VPCs with route tables for testing VPC peering.
# This module creates the prerequisites needed to test the vpc-peering module.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# Requester VPC (simulates Databricks workspace VPC)
resource "aws_vpc" "requester" {
  cidr_block = "10.1.0.0/16"

  tags = {
    Name = "tftest-vpc-peering-requester"
  }
}

resource "aws_route_table" "requester" {
  vpc_id = aws_vpc.requester.id

  tags = {
    Name = "tftest-vpc-peering-requester-rt"
  }
}

# Accepter VPC (simulates hub/shared services VPC)
resource "aws_vpc" "accepter" {
  cidr_block = "10.2.0.0/16"

  tags = {
    Name = "tftest-vpc-peering-accepter"
  }
}

resource "aws_route_table" "accepter" {
  vpc_id = aws_vpc.accepter.id

  tags = {
    Name = "tftest-vpc-peering-accepter-rt"
  }
}

output "requester_vpc_id" {
  value = aws_vpc.requester.id
}

output "requester_route_table_ids" {
  value = [aws_route_table.requester.id]
}

output "accepter_vpc_id" {
  value = aws_vpc.accepter.id
}

output "accepter_route_table_ids" {
  value = [aws_route_table.accepter.id]
}

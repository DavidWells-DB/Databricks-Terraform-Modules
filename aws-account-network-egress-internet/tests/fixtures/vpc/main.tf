terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# VPC for testing
resource "aws_vpc" "test" {
  cidr_block           = "10.5.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "tftest-egress-internet-vpc"
    Test = "integration-tftest"
  }
}

# Public subnets for NAT Gateway placement
resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.test.id
  cidr_block        = "10.5.101.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "tftest-public-a"
    Test = "integration-tftest"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.test.id
  cidr_block        = "10.5.102.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "tftest-public-b"
    Test = "integration-tftest"
  }
}

# Private subnets (for route table testing)
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.test.id
  cidr_block        = "10.5.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "tftest-private-a"
    Test = "integration-tftest"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.test.id
  cidr_block        = "10.5.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "tftest-private-b"
    Test = "integration-tftest"
  }
}

# Private route tables
resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.test.id

  tags = {
    Name = "tftest-private-rtb-a"
    Test = "integration-tftest"
  }
}

resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.test.id

  tags = {
    Name = "tftest-private-rtb-b"
    Test = "integration-tftest"
  }
}

# Route table associations
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_b.id
}

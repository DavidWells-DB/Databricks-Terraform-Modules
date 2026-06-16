terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_vpc" "test" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "tftest-vpc-endpoints-integ"
    Test = "integration-tftest"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.test.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "tftest-private-a"
    Test = "integration-tftest"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.test.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "tftest-private-b"
    Test = "integration-tftest"
  }
}

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

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_b.id
}

resource "aws_security_group" "endpoint" {
  vpc_id      = aws_vpc.test.id
  name        = "tftest-endpoint-sg"
  description = "Security group for VPC endpoints test"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Allow HTTPS from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "tftest-endpoint-sg"
    Test = "integration-tftest"
  }
}

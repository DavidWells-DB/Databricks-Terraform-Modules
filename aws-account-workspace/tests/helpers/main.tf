# Helper module to create workspace dependencies for integration testing.
# Creates: credentials, storage, and network registrations required by aws-account-workspace module.

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    databricks = {
      source                = "databricks/databricks"
      version               = ">= 1.50"
      configuration_aliases = [databricks.account]
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9"
    }
  }
}

# ===== CREDENTIALS =====

data "databricks_aws_assume_role_policy" "this" {
  provider      = databricks.account
  external_id   = var.databricks_account_id
  aws_partition = "aws"
}

data "databricks_aws_crossaccount_policy" "this" {
  provider      = databricks.account
  aws_partition = "aws"
}

resource "aws_iam_role" "credentials" {
  name               = "tftest-workspace-integ-role"
  assume_role_policy = data.databricks_aws_assume_role_policy.this.json
}

resource "aws_iam_role_policy" "credentials" {
  name   = "tftest-workspace-integ-role-policy"
  role   = aws_iam_role.credentials.id
  policy = data.databricks_aws_crossaccount_policy.this.json
}

resource "time_sleep" "iam_propagation" {
  depends_on      = [aws_iam_role_policy.credentials]
  create_duration = "30s"
}

resource "databricks_mws_credentials" "this" {
  provider         = databricks.account
  credentials_name = "tftest-workspace-integ-creds"
  role_arn         = aws_iam_role.credentials.arn
  depends_on       = [time_sleep.iam_propagation]
}

# ===== STORAGE =====

data "databricks_aws_bucket_policy" "this" {
  provider      = databricks.account
  bucket        = aws_s3_bucket.storage.id
  aws_partition = "aws"
}

resource "aws_s3_bucket" "storage" {
  bucket_prefix = "tftest-workspace-integ-dbfs-"
}

resource "aws_s3_bucket_versioning" "storage" {
  bucket = aws_s3_bucket.storage.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "storage" {
  bucket = aws_s3_bucket.storage.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "storage" {
  bucket                  = aws_s3_bucket.storage.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "storage" {
  bucket     = aws_s3_bucket.storage.id
  policy     = data.databricks_aws_bucket_policy.this.json
  depends_on = [aws_s3_bucket_public_access_block.storage]
}

resource "databricks_mws_storage_configurations" "this" {
  provider                   = databricks.account
  account_id                 = var.databricks_account_id
  storage_configuration_name = "tftest-workspace-integ-storage"
  bucket_name                = aws_s3_bucket.storage.id
  depends_on                 = [aws_s3_bucket_policy.storage]
}

# ===== NETWORK =====

resource "aws_vpc" "this" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "tftest-workspace-integ-vpc"
  }
}

resource "aws_subnet" "workspace" {
  count                   = 2
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet("10.0.0.0/16", 4, count.index)
  availability_zone       = count.index == 0 ? "us-east-1a" : "us-east-1b"
  map_public_ip_on_launch = false
  tags = {
    Name = "tftest-workspace-integ-subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "tftest-workspace-integ-igw"
  }
}

resource "aws_route_table" "this" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "tftest-workspace-integ-rt"
  }
}

resource "aws_route" "internet" {
  route_table_id         = aws_route_table.this.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "workspace" {
  count          = 2
  subnet_id      = aws_subnet.workspace[count.index].id
  route_table_id = aws_route_table.this.id
}

resource "aws_security_group" "workspace" {
  vpc_id = aws_vpc.this.id
  name   = "tftest-workspace-integ-sg"
  tags = {
    Name = "tftest-workspace-integ-sg"
  }
}

resource "aws_vpc_security_group_egress_rule" "workspace" {
  security_group_id = aws_security_group.workspace.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "workspace" {
  security_group_id            = aws_security_group.workspace.id
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.workspace.id
}

resource "databricks_mws_networks" "this" {
  provider           = databricks.account
  account_id         = var.databricks_account_id
  network_name       = "tftest-workspace-integ-network"
  vpc_id             = aws_vpc.this.id
  subnet_ids         = aws_subnet.workspace[*].id
  security_group_ids = [aws_security_group.workspace.id]
}

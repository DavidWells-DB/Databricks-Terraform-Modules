mock_provider "aws" {
  override_data {
    target = data.aws_iam_policy_document.s3_endpoint
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"*\"},\"Action\":\"s3:*\",\"Resource\":\"*\"}]}"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.sts_endpoint
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"*\"},\"Action\":\"sts:*\",\"Resource\":\"*\"}]}"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.kinesis_endpoint
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"*\"},\"Action\":\"kinesis:*\",\"Resource\":\"*\"}]}"
    }
  }
}

variables {
  vpc_id                  = "vpc-0123456789abcdef0"
  region                  = "us-east-1"
  private_subnet_ids      = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
  security_group_ids      = ["sg-0123456789abcdef0"]
  private_route_table_ids = ["rtb-0123456789abcdef0", "rtb-0123456789abcdef1"]
  databricks_gov_shard    = null
}

# --- gov_shard → aws_partition branching ---

run "commercial_shard_uses_aws_partition" {
  command = plan

  assert {
    condition     = output.aws_partition == "aws"
    error_message = "Commercial shard (null) should resolve to partition 'aws'"
  }
}

run "civilian_shard_uses_gov_partition" {
  command = plan

  variables {
    databricks_gov_shard = "civilian"
  }

  assert {
    condition     = output.aws_partition == "aws-us-gov"
    error_message = "GovCloud civilian shard should resolve to partition 'aws-us-gov'"
  }
}

run "dod_shard_uses_gov_partition" {
  command = plan

  variables {
    databricks_gov_shard = "dod"
  }

  assert {
    condition     = output.aws_partition == "aws-us-gov"
    error_message = "GovCloud DoD shard should resolve to partition 'aws-us-gov'"
  }
}

# --- Endpoint type assertions ---

run "s3_endpoint_is_gateway_type" {
  command = plan

  assert {
    condition     = aws_vpc_endpoint.s3.vpc_endpoint_type == "Gateway"
    error_message = "S3 endpoint must be type Gateway"
  }
}

run "sts_endpoint_is_interface_type" {
  command = plan

  assert {
    condition     = aws_vpc_endpoint.sts.vpc_endpoint_type == "Interface"
    error_message = "STS endpoint must be type Interface"
  }
}

run "kinesis_endpoint_is_interface_type" {
  command = plan

  assert {
    condition     = aws_vpc_endpoint.kinesis.vpc_endpoint_type == "Interface"
    error_message = "Kinesis endpoint must be type Interface"
  }
}

# --- Private DNS enabled on interface endpoints ---

run "sts_endpoint_has_private_dns_enabled" {
  command = plan

  assert {
    condition     = aws_vpc_endpoint.sts.private_dns_enabled == true
    error_message = "STS interface endpoint must have private_dns_enabled = true"
  }
}

run "kinesis_endpoint_has_private_dns_enabled" {
  command = plan

  assert {
    condition     = aws_vpc_endpoint.kinesis.private_dns_enabled == true
    error_message = "Kinesis interface endpoint must have private_dns_enabled = true"
  }
}

# --- Variable validation: vpc_id ---

run "invalid_vpc_id_rejected" {
  command = plan

  variables {
    vpc_id = "not-a-vpc-id"
  }

  expect_failures = [var.vpc_id]
}

# --- Variable validation: region ---

run "invalid_region_rejected" {
  command = plan

  variables {
    region = "not-a-region"
  }

  expect_failures = [var.region]
}

run "region_with_uppercase_rejected" {
  command = plan

  variables {
    region = "US-EAST-1"
  }

  expect_failures = [var.region]
}

# --- Variable validation: private_subnet_ids ---

run "empty_private_subnet_ids_rejected" {
  command = plan

  variables {
    private_subnet_ids = []
  }

  expect_failures = [var.private_subnet_ids]
}

run "invalid_subnet_id_rejected" {
  command = plan

  variables {
    private_subnet_ids = ["not-a-subnet-id"]
  }

  expect_failures = [var.private_subnet_ids]
}

# --- Variable validation: security_group_ids ---

run "empty_security_group_ids_rejected" {
  command = plan

  variables {
    security_group_ids = []
  }

  expect_failures = [var.security_group_ids]
}

run "invalid_security_group_id_rejected" {
  command = plan

  variables {
    security_group_ids = ["not-a-sg-id"]
  }

  expect_failures = [var.security_group_ids]
}

# --- Variable validation: private_route_table_ids ---

run "empty_route_table_ids_rejected" {
  command = plan

  variables {
    private_route_table_ids = []
  }

  expect_failures = [var.private_route_table_ids]
}

run "invalid_route_table_id_rejected" {
  command = plan

  variables {
    private_route_table_ids = ["not-a-rtb-id"]
  }

  expect_failures = [var.private_route_table_ids]
}

# --- Variable validation: databricks_gov_shard ---

run "invalid_gov_shard_rejected" {
  command = plan

  variables {
    databricks_gov_shard = "invalid-shard"
  }

  expect_failures = [var.databricks_gov_shard]
}

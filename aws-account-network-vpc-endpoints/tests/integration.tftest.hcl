# Integration tests — apply-command against real AWS.
#
# Requires:
#   - AWS credentials (via env: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN, AWS_DEFAULT_REGION)
#
# Run with: terraform test -filter=tests/integration.tftest.hcl

provider "aws" {
  region = "us-east-1"
}

variables {
  region               = "us-east-1"
  databricks_gov_shard = null
  tags = {
    Test = "integration-tftest"
  }
}

run "setup_vpc_infrastructure" {
  command = apply

  # Create minimal VPC infrastructure for testing
  module {
    source = "./tests/fixtures/vpc"
  }
}

run "applies_and_creates_vpc_endpoints" {
  command = apply

  variables {
    vpc_id                  = run.setup_vpc_infrastructure.vpc_id
    private_subnet_ids      = run.setup_vpc_infrastructure.private_subnet_ids
    security_group_ids      = [run.setup_vpc_infrastructure.security_group_id]
    private_route_table_ids = run.setup_vpc_infrastructure.private_route_table_ids
  }

  assert {
    condition     = output.s3_endpoint_id != ""
    error_message = "Expected non-empty s3_endpoint_id after successful apply"
  }

  assert {
    condition     = startswith(output.s3_endpoint_arn, "arn:aws:ec2:us-east-1:")
    error_message = "Expected s3_endpoint_arn to start with arn:aws:ec2:us-east-1:"
  }

  assert {
    condition     = length(output.s3_cidr_blocks) > 0
    error_message = "Expected s3_cidr_blocks to be non-empty"
  }

  assert {
    condition     = output.sts_endpoint_id != ""
    error_message = "Expected non-empty sts_endpoint_id after successful apply"
  }

  assert {
    condition     = startswith(output.sts_endpoint_arn, "arn:aws:ec2:us-east-1:")
    error_message = "Expected sts_endpoint_arn to start with arn:aws:ec2:us-east-1:"
  }

  assert {
    condition     = length(output.sts_dns_entries) > 0
    error_message = "Expected sts_dns_entries to be non-empty"
  }

  assert {
    condition     = output.kinesis_endpoint_id != ""
    error_message = "Expected non-empty kinesis_endpoint_id after successful apply"
  }

  assert {
    condition     = startswith(output.kinesis_endpoint_arn, "arn:aws:ec2:us-east-1:")
    error_message = "Expected kinesis_endpoint_arn to start with arn:aws:ec2:us-east-1:"
  }

  assert {
    condition     = length(output.kinesis_dns_entries) > 0
    error_message = "Expected kinesis_dns_entries to be non-empty"
  }

  assert {
    condition     = output.aws_partition == "aws"
    error_message = "Expected aws_partition to be 'aws' for commercial region"
  }
}

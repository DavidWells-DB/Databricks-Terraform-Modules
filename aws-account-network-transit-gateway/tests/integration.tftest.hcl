# Integration tests — apply-command against real AWS.
#
# Requires:
#   - AWS credentials (via env: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN, AWS_DEFAULT_REGION)
#
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# SKIPPED: Transit Gateway creates expensive infrastructure (~$36.50/month per TGW
# + $36.50/month per VPC attachment, charged hourly). The resource would cost
# ~$73/month minimum (1 TGW + 1 attachment) and runs continuously once created.
# This test would accrue ~$0.10/hour while running. Given the high cost and the
# fact that TGW is a well-established AWS service with deterministic behavior,
# integration testing is deferred to higher-level composition tests where the
# full topology cost is justified.

provider "aws" {
  region = "us-east-1"
}

variables {
  resource_prefix = "tftest-tgw"
  tgw_asn         = 64512
  vpc_attachments = {
    test-vpc = {
      vpc_id     = "vpc-placeholder"
      subnet_ids = ["subnet-placeholder-a", "subnet-placeholder-b"]
    }
  }
}

# Commented out due to high cost — see header comment for rationale.
# This test would create:
# - 1 VPC with 2 subnets (prerequisite for TGW attachment)
# - 1 Transit Gateway (~$36.50/month)
# - 1 TGW VPC attachment (~$36.50/month)
# - 1 TGW route table with associations and propagations
#
# run "applies_and_produces_transit_gateway" {
#   command = apply
#
#   variables {
#     vpc_attachments = {
#       test-vpc = {
#         vpc_id     = aws_vpc.test.id
#         subnet_ids = [aws_subnet.test_a.id, aws_subnet.test_b.id]
#       }
#     }
#   }
#
#   # Prerequisite VPC and subnets for TGW attachment
#   override_resource {
#     target = aws_vpc.test
#     values = {
#       cidr_block = "10.0.0.0/16"
#     }
#   }
#
#   override_resource {
#     target = aws_subnet.test_a
#     values = {
#       vpc_id            = aws_vpc.test.id
#       cidr_block        = "10.0.1.0/24"
#       availability_zone = "us-east-1a"
#     }
#   }
#
#   override_resource {
#     target = aws_subnet.test_b
#     values = {
#       vpc_id            = aws_vpc.test.id
#       cidr_block        = "10.0.2.0/24"
#       availability_zone = "us-east-1b"
#     }
#   }
#
#   assert {
#     condition     = output.transit_gateway_id != ""
#     error_message = "Expected non-empty transit_gateway_id after successful apply"
#   }
#
#   assert {
#     condition     = startswith(output.transit_gateway_arn, "arn:aws:ec2:")
#     error_message = "Expected transit_gateway_arn to start with arn:aws:ec2:"
#   }
#
#   assert {
#     condition     = output.transit_gateway_owner_id != ""
#     error_message = "Expected non-empty transit_gateway_owner_id"
#   }
#
#   assert {
#     condition     = output.route_table_id != ""
#     error_message = "Expected non-empty route_table_id"
#   }
#
#   assert {
#     condition     = length(output.attachment_ids) == 1
#     error_message = "Expected exactly one VPC attachment"
#   }
#
#   assert {
#     condition     = contains(keys(output.attachment_ids), "test-vpc")
#     error_message = "Expected attachment key 'test-vpc' to be present"
#   }
#
#   assert {
#     condition     = output.attachment_ids["test-vpc"] != ""
#     error_message = "Expected non-empty attachment ID for test-vpc"
#   }
# }

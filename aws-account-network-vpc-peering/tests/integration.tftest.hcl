# Integration tests — apply-command against a real AWS account.
#
# Requires:
#   - AWS credentials (via env: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN, AWS_DEFAULT_REGION)
#   - AWS account ID passed as var.aws_account_id
#
# Run with: terraform test -filter=tests/integration.tftest.hcl -var="aws_account_id=<account_id>"
#
# This test creates two minimal VPCs to test the peering functionality.

provider "aws" {
  region = "us-east-1"
}

variable "aws_account_id" {
  type = string
}

run "setup_vpcs" {
  command = apply

  module {
    source = "./tests/fixtures"
  }
}

run "applies_and_creates_peering" {
  command = apply

  variables {
    requester_vpc_id          = run.setup_vpcs.requester_vpc_id
    accepter_vpc_id           = run.setup_vpcs.accepter_vpc_id
    requester_route_table_ids = run.setup_vpcs.requester_route_table_ids
    accepter_route_table_ids  = run.setup_vpcs.accepter_route_table_ids
    requester_vpc_cidr        = "10.1.0.0/16"
    accepter_vpc_cidr         = "10.2.0.0/16"
    accepter_account_id       = var.aws_account_id
    accepter_region           = "us-east-1"
    peering_name              = "tftest-vpc-peering-integ"
    tags = {
      Environment = "integration-test"
      Purpose     = "terraform-test"
    }
  }

  assert {
    condition     = output.peering_connection_id != ""
    error_message = "Expected non-empty peering_connection_id after successful apply"
  }

  assert {
    condition     = startswith(output.peering_connection_id, "pcx-")
    error_message = "Expected peering_connection_id to start with pcx-"
  }

  assert {
    condition     = output.peering_connection_status == "active"
    error_message = "Expected peering_connection_status to be active after acceptance"
  }

  assert {
    condition     = length(output.requester_route_ids) == 1
    error_message = "Expected one route in requester route table"
  }

  assert {
    condition     = length(output.accepter_route_ids) == 1
    error_message = "Expected one route in accepter route table"
  }
}

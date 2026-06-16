# Integration tests — apply-command against a real AWS account.
#
# Credential-gated. Requires:
#   - AWS credentials with NetworkFirewall and EC2 (route table) admin in the target account
#   - A pre-existing VPC with firewall subnets and private route tables
#
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# SKIPPED: AWS Network Firewall charges approximately $0.40/hour per firewall endpoint
# plus data processing fees. A minimal 2-AZ deployment costs approximately $600/month.
# The module's correctness is validated via plan tests in plan.tftest.hcl.
# Integration testing would provide limited incremental value at significant ongoing cost.
#
# These tests would verify:
#   1. The module actually creates the Network Firewall, policy, and routes against a live AWS account.
#   2. Tier-gated failure surfaces loudly (DATABRICKS_RULES.md Rule 4.1) — when the workspace consuming
#      this firewall's route tables is Standard-tier, the workspace API rejects and the apply fails
#      clearly. The firewall itself is AWS-only and does not require a specific Databricks tier, but the
#      workspace network security controls that consume the firewall output are Premium-gated.
#
# The plan-command tests in plan.tftest.hcl cover static / mock-provider cases.

provider "aws" {
  region = "us-east-1"
}

variables {
  vpc_id                  = "vpc-00000000000000000"  # Placeholder — test is skipped
  firewall_name           = "tftest-network-firewall-integ"
  firewall_subnet_ids     = ["subnet-00000000000000000", "subnet-11111111111111111"]
  private_route_table_ids = ["rtb-00000000000000000", "rtb-11111111111111111"]
  tags = {
    Test   = "integration"
    Module = "aws-account-network-firewall"
  }
}

# SKIPPED: Uncomment to run against real AWS (expensive — ~$0.40/hr per firewall endpoint).
#
# Prerequisites: requires VPC with firewall subnets and private route tables.
# You can create these inline or use the aws-account-network-vpc module:
#
# run "setup_vpc" {
#   command = apply
#
#   module {
#     source = "../../aws-account-network-vpc"
#   }
#
#   variables {
#     vpc_name                       = "tftest-network-firewall-integ-vpc"
#     vpc_cidr                       = "10.0.0.0/16"
#     workspace_subnets_cidrs        = ["10.0.1.0/24", "10.0.2.0/24"]
#     availability_zones             = ["us-east-1a", "us-east-1b"]
#     firewall_subnets_cidrs         = ["10.0.10.0/28", "10.0.10.16/28"]
#     databricks_account_id          = "none"
#     enable_databricks_registration = false
#   }
# }
#
# run "applies_and_creates_firewall" {
#   command = apply
#
#   variables {
#     vpc_id                  = run.setup_vpc.vpc_id
#     firewall_subnet_ids     = run.setup_vpc.firewall_subnet_ids
#     private_route_table_ids = run.setup_vpc.private_route_table_ids
#   }
#
#   assert {
#     condition     = output.firewall_id != ""
#     error_message = "Expected non-empty firewall_id after successful apply"
#   }
#
#   assert {
#     condition     = startswith(output.firewall_arn, "arn:aws:network-firewall:")
#     error_message = "Expected firewall_arn to start with arn:aws:network-firewall:"
#   }
#
#   assert {
#     condition     = startswith(output.firewall_policy_arn, "arn:aws:network-firewall:")
#     error_message = "Expected firewall_policy_arn to start with arn:aws:network-firewall:"
#   }
#
#   assert {
#     condition     = length(output.firewall_endpoint_ids) == 2
#     error_message = "Expected 2 firewall endpoint IDs for 2-AZ deployment"
#   }
#
#   assert {
#     condition     = alltrue([for id in output.firewall_endpoint_ids : startswith(id, "vpce-")])
#     error_message = "Expected all firewall endpoint IDs to start with vpce-"
#   }
#
#   assert {
#     condition     = output.firewall_policy_id != ""
#     error_message = "Expected non-empty firewall_policy_id"
#   }
#
#   assert {
#     condition     = length(output.firewall_status) > 0
#     error_message = "Expected non-empty firewall_status output"
#   }
# }
#
# # Tier-gated failure test: deploy against a workspace below Premium tier and confirm failure.
# # Per DATABRICKS_RULES.md Rule 2.3 + 4.1: this test is the empirical enforcement of the
# # README's "Minimum tier: Premium" claim for the workspace security controls consuming this firewall.
# #
# # Enable by pointing at a Standard-tier workspace and verifying the network policy API rejects.
# # Skipped until a Standard-tier test environment is provisioned.
# #
# # run "workspace_network_policy_fails_against_standard_tier" {
# #   command = apply
# #
# #   variables {
# #     firewall_subnet_ids     = ["subnet-REPLACE_ME_1"]
# #     private_route_table_ids = ["rtb-REPLACE_ME_1"]
# #   }
# #
# #   # The Network Firewall resource itself will succeed; however any Databricks workspace
# #   # network configuration that references this firewall's route tables will fail at the
# #   # Databricks API layer when the workspace is Standard tier.
# #   expect_failures = []
# # }

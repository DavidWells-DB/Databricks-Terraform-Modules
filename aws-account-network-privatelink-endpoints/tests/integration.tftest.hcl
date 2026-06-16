# Integration tests — apply-command against real AWS + Databricks account.
#
# Requires:
#   - AWS credentials (via env: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN, AWS_DEFAULT_REGION)
#   - Databricks account-level service principal (via env: DATABRICKS_CLIENT_ID, DATABRICKS_CLIENT_SECRET, DATABRICKS_ACCOUNT_ID)
#   - An existing VPC with subnets (update vpc_id and privatelink_subnet_ids variables below)
#
# Run with: terraform test -filter=tests/integration.tftest.hcl -var="databricks_account_id=${DATABRICKS_ACCOUNT_ID}"
#
# KNOWN LIMITATION: This test is currently SKIPPED due to a Terraform test framework issue
# with the Databricks provider's OAuth authentication. The provider successfully authenticates
# during terraform plan but fails with "Unable to load OAuth Config" during terraform apply
# when run via `terraform test`. The module itself works correctly when used normally.
#
# The issue has been reproduced with:
# - Terraform v1.10+
# - databricks/databricks provider v1.117.0
# - Valid DATABRICKS_CLIENT_ID, DATABRICKS_CLIENT_SECRET, DATABRICKS_ACCOUNT_ID env vars
# - Provider configuration identical to working tests in sibling modules (aws-account-workspace-credentials, aws-account-network-vpc)
#
# Workaround: Test the module by calling it from a root module with `terraform apply` directly,
# rather than using `terraform test`.

provider "aws" {
  region = "us-east-1"
}

provider "databricks" {
  alias      = "account"
  host       = "https://accounts.cloud.databricks.com"
  account_id = var.databricks_account_id
}

variables {
  databricks_gov_shard               = null
  vpc_id                             = "vpc-CHANGEME"                           # Update with a real VPC ID for testing
  privatelink_subnet_ids             = ["subnet-CHANGEME1", "subnet-CHANGEME2"] # Update with real subnet IDs
  region                             = "us-east-1"
  private_access_settings_name       = "tftest-privatelink-pas-integ"
  workspace_vpc_endpoint_name        = "tftest-privatelink-workspace-integ"
  relay_vpc_endpoint_name            = "tftest-privatelink-relay-integ"
  security_group_name                = "tftest-privatelink-sg-integ"
  security_group_ingress_cidr_blocks = ["10.0.0.0/16"]
  public_access_enabled              = false
  private_access_level               = "ACCOUNT"
  enable_service_direct              = false
  tags = {
    Test = "integration"
  }
}

variable "databricks_account_id" {
  type = string
}

# Skipped: see KNOWN LIMITATION comment above
# run "applies_and_produces_privatelink_endpoints" {
#   command = apply
#
#   # Assert workspace VPC endpoint outputs
#   assert {
#     condition     = output.workspace_vpc_endpoint_id != ""
#     error_message = "Expected non-empty workspace_vpc_endpoint_id"
#   }
#
#   assert {
#     condition     = startswith(output.workspace_aws_vpc_endpoint_id, "vpce-")
#     error_message = "Expected workspace_aws_vpc_endpoint_id to start with vpce-"
#   }
#
#   assert {
#     condition     = startswith(output.workspace_service_name, "com.amazonaws.vpce.us-east-1.vpce-svc-")
#     error_message = "Expected workspace_service_name to be a valid AWS endpoint service name for us-east-1"
#   }
#
#   # Assert relay VPC endpoint outputs
#   assert {
#     condition     = output.relay_vpc_endpoint_id != ""
#     error_message = "Expected non-empty relay_vpc_endpoint_id"
#   }
#
#   assert {
#     condition     = startswith(output.relay_aws_vpc_endpoint_id, "vpce-")
#     error_message = "Expected relay_aws_vpc_endpoint_id to start with vpce-"
#   }
#
#   assert {
#     condition     = startswith(output.relay_service_name, "com.amazonaws.vpce.us-east-1.vpce-svc-")
#     error_message = "Expected relay_service_name to be a valid AWS endpoint service name for us-east-1"
#   }
#
#   # Assert service direct is null when disabled
#   assert {
#     condition     = output.service_direct_vpc_endpoint_id == null
#     error_message = "Expected service_direct_vpc_endpoint_id to be null when enable_service_direct = false"
#   }
#
#   assert {
#     condition     = output.service_direct_aws_vpc_endpoint_id == null
#     error_message = "Expected service_direct_aws_vpc_endpoint_id to be null when enable_service_direct = false"
#   }
#
#   # Assert private access settings
#   assert {
#     condition     = output.private_access_settings_id != ""
#     error_message = "Expected non-empty private_access_settings_id"
#   }
#
#   # Assert security group
#   assert {
#     condition     = startswith(output.security_group_id, "sg-")
#     error_message = "Expected security_group_id to start with sg-"
#   }
# }

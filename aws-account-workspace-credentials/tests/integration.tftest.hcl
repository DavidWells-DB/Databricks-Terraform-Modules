# Integration tests — apply-command against real AWS + Databricks account.
#
# Requires:
#   - AWS credentials (via env: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN, AWS_DEFAULT_REGION)
#   - Databricks account-level service principal (via env: DATABRICKS_CLIENT_ID, DATABRICKS_CLIENT_SECRET, DATABRICKS_ACCOUNT_ID)
#
# Run with: terraform test -filter=tests/integration.tftest.hcl

provider "aws" {
  region = "us-east-1"
}

provider "databricks" {
  alias      = "account"
  host       = "https://accounts.cloud.databricks.com"
  account_id = var.databricks_account_id
}

variables {
  aws_partition        = "aws"
  databricks_gov_shard = null
  role_name            = "tftest-workspace-credentials-integ"
  credentials_name     = "tftest-creds-integ"
}

variable "databricks_account_id" {
  type = string
}

run "applies_and_produces_credentials" {
  command = apply

  assert {
    condition     = output.credentials_id != ""
    error_message = "Expected non-empty credentials_id after successful apply"
  }

  assert {
    condition     = startswith(output.role_arn, "arn:aws:iam::")
    error_message = "Expected role_arn to start with arn:aws:iam:: for commercial partition"
  }

  assert {
    condition     = output.role_name == "tftest-workspace-credentials-integ"
    error_message = "Expected role_name to match input"
  }

  assert {
    condition     = output.databricks_aws_account_id == "414351767826"
    error_message = "Expected commercial Databricks AWS account ID"
  }
}

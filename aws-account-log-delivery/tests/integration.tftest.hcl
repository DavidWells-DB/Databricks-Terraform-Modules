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
  resource_prefix      = "tftest-log-delivery"
  log_types            = ["AUDIT_LOGS"]
}

variable "databricks_account_id" {
  type = string
}

run "applies_against_premium_account" {
  command = apply

  assert {
    condition     = output.bucket_name == "tftest-log-delivery-log-delivery"
    error_message = "Expected bucket_name to match resource_prefix pattern"
  }

  assert {
    condition     = startswith(output.bucket_arn, "arn:aws:s3::")
    error_message = "Expected bucket_arn to start with arn:aws:s3::"
  }

  assert {
    condition     = startswith(output.role_arn, "arn:aws:iam::")
    error_message = "Expected role_arn to start with arn:aws:iam:: for commercial partition"
  }

  assert {
    condition     = output.credentials_id != ""
    error_message = "Expected non-empty credentials_id after successful apply"
  }

  assert {
    condition     = output.storage_configuration_id != ""
    error_message = "Expected non-empty storage_configuration_id after successful apply"
  }

  assert {
    condition     = length(output.log_delivery_configuration_ids) == 1
    error_message = "Expected one log delivery configuration ID for AUDIT_LOGS"
  }

  assert {
    condition     = contains(keys(output.log_delivery_configuration_ids), "AUDIT_LOGS")
    error_message = "Expected AUDIT_LOGS in log_delivery_configuration_ids"
  }

  assert {
    condition     = output.log_delivery_configuration_ids["AUDIT_LOGS"] != ""
    error_message = "Expected non-empty config_id for AUDIT_LOGS"
  }

  assert {
    condition     = output.databricks_aws_account_id == "414351767826"
    error_message = "Expected commercial Databricks AWS account ID"
  }
}

# Tier-gated failure test: against a Standard-tier account, expect failure.
# Per DATABRICKS_RULES.md Rule 2.3 + 4.1: this test is the empirical enforcement of the
# README's "Minimum tier: Premium" claim.
#
# Enable by overriding `databricks_account_id` to point at a Standard-tier account.
# Skipped until a Standard-tier test account is provisioned.
#
# run "fails_against_standard_tier_account" {
#   command = apply
#
#   variables {
#     databricks_account_id = "<standard-tier-account-id>"
#   }
#
#   expect_failures = [
#     databricks_mws_log_delivery.this,
#   ]
# }

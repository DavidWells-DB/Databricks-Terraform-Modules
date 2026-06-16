# Integration tests — apply-command against real AWS + Databricks account.
#
# Credential-gated. Requires:
#   - AWS credentials with S3 admin in the target account
#   - DATABRICKS_HOST, DATABRICKS_CLIENT_ID, DATABRICKS_CLIENT_SECRET, DATABRICKS_ACCOUNT_ID env vars
#
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# These tests verify:
#   1. The module actually creates the S3 bucket and registers the storage configuration against a live
#      Databricks account.
#   2. Tier-gated failure surfaces loudly (DATABRICKS_RULES.md Rule 4.1) — when applied against a
#      Standard-tier account, the API rejects and the apply fails clearly.
#
# The plan-command tests in plan.tftest.hcl cover the static / mock-provider cases. This file covers
# the integration cases that require real cloud credentials.

provider "aws" {
  region = "us-east-1"
}

provider "databricks" {
  alias      = "account"
  host       = "https://accounts.cloud.databricks.com"
  account_id = var.databricks_account_id
}

variable "databricks_account_id" {
  type = string
}

variables {
  aws_partition              = "aws"
  databricks_gov_shard       = null
  bucket_name                = "tftest-aws-account-workspace-storage"
  storage_configuration_name = "tftest-storage"
}

# Smoke test: module applies cleanly against a Premium+ account and produces a usable storage_configuration_id.
run "applies_against_premium_account" {
  command = apply

  assert {
    condition     = output.storage_configuration_id != ""
    error_message = "Expected non-empty storage_configuration_id after successful apply"
  }

  assert {
    condition     = output.bucket_name == "tftest-aws-account-workspace-storage"
    error_message = "Expected bucket_name to match input"
  }

  assert {
    condition     = startswith(output.bucket_arn, "arn:aws:s3:::")
    error_message = "Expected bucket_arn to start with arn:aws:s3::: for commercial partition"
  }

  assert {
    condition     = can(regex("\\.s3\\.us-east-1\\.amazonaws\\.com$", output.bucket_domain_name))
    error_message = "Expected bucket_domain_name to end with .s3.us-east-1.amazonaws.com"
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
#     databricks_mws_storage_configurations.this,
#   ]
# }

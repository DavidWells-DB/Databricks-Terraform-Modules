# Integration tests — apply-command against a real Databricks account (Premium+).
#
# IMPORTANT: This module requires pre-existing credentials_id, storage_configuration_id, and
# databricks_network_id. These are expensive/complex to create inline, so this test uses a
# helper module to create them.
#
# Credential-gated. Requires:
#   - DATABRICKS_HOST, DATABRICKS_CLIENT_ID, DATABRICKS_CLIENT_SECRET, DATABRICKS_ACCOUNT_ID env vars
#   - AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN, AWS_DEFAULT_REGION env vars
#   - A Premium or Enterprise Databricks account on AWS
#
# Run with: terraform test -filter=tests/integration.tftest.hcl -var="databricks_account_id=${DATABRICKS_ACCOUNT_ID}"
#
# These tests verify:
#   1. The module actually creates a workspace against a live Databricks account.
#   2. The workspace URL is non-empty and parseable after DNS propagation.

provider "databricks" {
  alias      = "account"
  host       = "https://accounts.cloud.databricks.com"
  account_id = var.databricks_account_id
}

provider "aws" {
  region = "us-east-1"
}

variable "databricks_account_id" {
  type = string
}

variables {
  databricks_gov_shard = null
  workspace_name       = "tftest-aws-account-workspace"
  region               = "us-east-1"
}

# Setup run: create all prerequisites using a helper module
run "setup_dependencies" {
  command = apply

  module {
    source = "./tests/helpers"
  }

  variables {
    databricks_account_id = var.databricks_account_id
  }
}

# Smoke test: module applies cleanly against a Premium+ account and produces a usable workspace_url.
run "applies_against_premium_account" {
  command = apply

  variables {
    databricks_account_id    = var.databricks_account_id
    workspace_name           = "tftest-aws-account-workspace"
    region                   = "us-east-1"
    databricks_gov_shard     = null
    credentials_id           = run.setup_dependencies.credentials_id
    storage_configuration_id = run.setup_dependencies.storage_configuration_id
    databricks_network_id    = run.setup_dependencies.databricks_network_id
  }

  assert {
    condition     = output.workspace_id != 0
    error_message = "Expected non-zero workspace_id after successful apply"
  }

  assert {
    condition     = startswith(output.workspace_url, "https://")
    error_message = "Expected workspace_url to begin with https://"
  }

  assert {
    condition     = output.deployment_name != ""
    error_message = "Expected non-empty deployment_name after successful apply"
  }

  assert {
    condition     = output.workspace_host == output.workspace_url
    error_message = "Expected workspace_host to match workspace_url"
  }

  assert {
    condition     = output.dns_propagation_complete != ""
    error_message = "Expected dns_propagation_complete to be set after time_sleep completes"
  }

  assert {
    condition     = output.databricks_host == "https://accounts.cloud.databricks.com"
    error_message = "Expected databricks_host to be commercial account host for null gov_shard"
  }
}

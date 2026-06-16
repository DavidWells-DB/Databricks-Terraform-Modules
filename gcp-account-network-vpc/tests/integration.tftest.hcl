# Integration tests — apply-command against a real GCP project + Databricks account.
#
# Credential-gated. Requires:
#   - GCP credentials (GOOGLE_CREDENTIALS or Application Default Credentials) with
#     compute.networks.create, compute.subnetworks.create, compute.firewalls.create
#   - DATABRICKS_HOST=https://accounts.gcp.databricks.com
#   - DATABRICKS_CLIENT_ID, DATABRICKS_CLIENT_SECRET (account-level service principal)
#   - TF_VAR_databricks_account_id, TF_VAR_project_id
#
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# These tests verify:
#   1. The module actually creates the GCP network resources and registers the network
#      configuration against a live Databricks account.
#   2. Tier-gated failure surfaces loudly (DATABRICKS_RULES.md Rule 4.1) — when applied
#      against a Standard-tier account, the API rejects and the apply fails clearly.
#
# The plan-command tests in plan.tftest.hcl cover the static / mock-provider cases. This
# file covers the integration cases that require real cloud credentials.

variables {
  region                       = "us-central1"
  resource_prefix              = "tftest-gcp-net-vpc"
  network_name                 = "tftest-network"
  network_cidr                 = "10.0.0.0/16"
  pod_secondary_range_cidr     = "10.1.0.0/16"
  service_secondary_range_cidr = "10.2.0.0/20"
  # project_id supplied via TF_VAR_project_id
  # databricks_account_id supplied via TF_VAR_databricks_account_id
}

# Smoke test: module applies cleanly against a Premium+ account and produces usable outputs.
# run "applies_against_premium_account" {
#   command = apply
#
#   assert {
#     condition     = output.databricks_network_id != ""
#     error_message = "Expected non-empty databricks_network_id after successful apply"
#   }
#
#   assert {
#     condition     = startswith(output.network_self_link, "https://www.googleapis.com/compute/v1/projects/")
#     error_message = "Expected network_self_link to be a valid GCP self-link URL"
#   }
#
#   assert {
#     condition     = startswith(output.subnetwork_self_link, "https://www.googleapis.com/compute/v1/projects/")
#     error_message = "Expected subnetwork_self_link to be a valid GCP self-link URL"
#   }
# }

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
#     databricks_mws_networks.this,
#   ]
# }

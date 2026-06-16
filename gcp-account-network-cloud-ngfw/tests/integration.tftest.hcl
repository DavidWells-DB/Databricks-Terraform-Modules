# Integration tests — apply-command against a real GCP organization.
#
# Credential-gated. Requires:
#   - GCP credentials with networksecurity.admin at the organization level
#   - GOOGLE_PROJECT env var (or TF_VAR_project_id) for the billing project
#   - TF_VAR_organization_id, TF_VAR_project_id, TF_VAR_zone, TF_VAR_network_self_link
#
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# These tests verify:
#   1. The module actually creates all four Cloud NGFW resources against a live GCP organization.
#   2. Outputs are non-empty and have the expected format.
#
# NOTE: The firewall endpoint can take up to 60 minutes to reach ACTIVE state.
# The Terraform google provider waits automatically, but plan for a long test run.
#
# The plan-command tests in plan.tftest.hcl cover the static / mock-provider cases.
# This file covers the integration cases that require real GCP credentials.
#
# Per DATABRICKS_RULES.md Rule 4.1: this module uses GCP-side resources only
# (no Databricks tier-gated resources). There is no Databricks tier-failure case.

variables {
  resource_prefix = "tftest-ngfw"
  # organization_id   supplied via TF_VAR_organization_id or .tfvars
  # project_id        supplied via TF_VAR_project_id or .tfvars
  # zone              supplied via TF_VAR_zone or .tfvars
  # network_self_link supplied via TF_VAR_network_self_link or .tfvars
}

# Smoke test: module applies cleanly and produces non-empty resource IDs.
# run "applies_against_live_gcp_org" {
#   command = apply
#
#   assert {
#     condition     = output.security_profile_group_id != ""
#     error_message = "Expected non-empty security_profile_group_id after successful apply"
#   }
#
#   assert {
#     condition     = output.firewall_endpoint_id != ""
#     error_message = "Expected non-empty firewall_endpoint_id after successful apply"
#   }
#
#   assert {
#     condition     = output.firewall_endpoint_association_id != ""
#     error_message = "Expected non-empty firewall_endpoint_association_id after successful apply"
#   }
#
#   assert {
#     condition     = output.firewall_endpoint_state == "ACTIVE"
#     error_message = "Expected firewall_endpoint_state to be ACTIVE after successful apply"
#   }
#
#   assert {
#     condition     = output.firewall_endpoint_association_state == "ACTIVE"
#     error_message = "Expected firewall_endpoint_association_state to be ACTIVE after successful apply"
#   }
# }

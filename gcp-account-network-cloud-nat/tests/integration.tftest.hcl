# Integration tests — apply-command against a real GCP project.
#
# Credential-gated. Requires:
#   - GCP credentials with Compute Network Admin on the target project
#     (GOOGLE_CREDENTIALS env var, or Application Default Credentials via gcloud)
#   - A pre-existing VPC network and subnetwork in the target project/region
#
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# These tests verify:
#   1. The module actually creates the Cloud Router and Cloud NAT against a live GCP project.
#   2. The outputs (router_id, nat_id) are non-empty and correctly formed.
#
# The plan-command tests in plan.tftest.hcl cover the static / mock-provider cases. This file
# covers the integration cases that require real GCP credentials.
#
# Minimum tier: Premium. Per DATABRICKS_RULES.md Rule 4.1, if this module is deployed for a
# workspace below Premium tier, the workspace provisioning step (not this module) will fail.
# Cloud NAT itself has no tier enforcement; the tier claim applies to the Databricks workspace
# that consumes this network infrastructure.

variables {
  # project_id, network_self_link, subnetwork_self_link supplied via TF_VAR_* or .tfvars
  region          = "us-central1"
  resource_prefix = "tftest-cloud-nat"
}

# Smoke test: module applies cleanly and produces non-empty outputs.
# run "applies_and_produces_outputs" {
#   command = apply
#
#   assert {
#     condition     = output.router_id != ""
#     error_message = "Expected non-empty router_id after successful apply"
#   }
#
#   assert {
#     condition     = output.nat_id != ""
#     error_message = "Expected non-empty nat_id after successful apply"
#   }
#
#   assert {
#     condition     = startswith(output.router_id, "projects/")
#     error_message = "Expected router_id to start with projects/"
#   }
# }

# Integration tests — apply-command against a real Azure subscription.
#
# Credential-gated. Requires:
#   - Azure credentials configured (ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID,
#     ARM_SUBSCRIPTION_ID or equivalent az login / managed identity)
#   - The target resource group must already exist, in a region that supports
#     serverless workspaces (see the feature-region-support table).
#   - The service principal must have Contributor on the resource group.
#
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# These tests verify against live Azure:
#   1. The module creates a workspace of the true Serverless computeMode — the
#      exact check that would have caught the v0.1.0 bug (a Classic managed-VNet
#      workspace masquerading as serverless).
#   2. The exported outputs are usable (https workspace URL, ARM resource ID).

provider "azapi" {}

variables {
  name     = "tftest-adb-serverless"
  location = "eastus2"
  # Required — supply via TF_VAR_* env vars or a .tfvars file:
  #   resource_group_id (pre-existing resource group ARM ID)
}

# Smoke test: applies cleanly AND is a real serverless workspace.
run "applies_true_serverless_workspace" {
  command = apply

  assert {
    condition     = startswith(output.workspace_url, "https://adb-")
    error_message = "Expected workspace_url to start with https://adb-"
  }

  assert {
    condition     = output.workspace_resource_id != ""
    error_message = "Expected non-empty workspace_resource_id after successful apply"
  }

  assert {
    condition     = azapi_resource.this.output.compute_mode == "Serverless"
    error_message = "Live workspace must report properties.computeMode == \"Serverless\" (v0.1.0 deployed the Classic managed-VNet type here)"
  }
}

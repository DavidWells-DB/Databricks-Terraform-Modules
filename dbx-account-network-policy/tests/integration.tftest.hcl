# Integration tests — apply-command against a real Databricks account.
#
# This module shipped three defects that plan-only testing passed and only surfaced at
# apply time (open-items E6, E7, E11): a wrong egress enum, a wrong internet-destination
# type, and a perpetual-replacement idempotency bug. This file is the apply-level coverage
# that would have caught them; the idempotency dimension (E11) is enforced by the harness
# idempotency-check.sh, since `terraform test` has no native "assert no changes".
#
# Credential-gated. Requires:
#   - DATABRICKS_HOST (account host), DATABRICKS_CLIENT_ID, DATABRICKS_CLIENT_SECRET,
#     DATABRICKS_ACCOUNT_ID env vars for the account provider
#
# Run with: terraform test -filter=tests/integration.tftest.hcl -var="databricks_account_id=${DATABRICKS_ACCOUNT_ID}"

provider "databricks" {
  alias      = "account"
  host       = "https://accounts.cloud.databricks.com"
  account_id = var.databricks_account_id
}

variable "databricks_account_id" {
  type = string
}

variables {
  policy_name = "tftest-network-policy"
  egress_mode = "RESTRICTED_ACCESS"
  allowed_internet_destinations = [
    {
      destination               = "pypi.org"
      internet_destination_type = "DNS_NAME"
    }
  ]
}

# Smoke test: the policy applies against a live account with the correct enums.
# Asserts the exact values that were wrong in E6 (egress restriction_mode) so a
# regression fails here rather than at a downstream blueprint apply.
run "applies_with_correct_enums" {
  command = apply

  assert {
    condition     = output.network_policy_id != ""
    error_message = "Expected non-empty network_policy_id after successful apply"
  }

  assert {
    condition     = output.egress_mode == "RESTRICTED_ACCESS"
    error_message = "Expected egress restriction_mode RESTRICTED_ACCESS (E6: this enum was wrong and crashed the provider)"
  }
}

# FULL_ACCESS is the other valid egress enum (the PoC/open posture). Verifies the module
# applies cleanly in that mode too — the other half of the E6 enum surface.
run "applies_full_access_mode" {
  command = apply

  variables {
    policy_name                   = "tftest-network-policy-open"
    egress_mode                   = "FULL_ACCESS"
    allowed_internet_destinations = []
  }

  assert {
    condition     = output.egress_mode == "FULL_ACCESS"
    error_message = "Expected egress restriction_mode FULL_ACCESS in open posture"
  }
}

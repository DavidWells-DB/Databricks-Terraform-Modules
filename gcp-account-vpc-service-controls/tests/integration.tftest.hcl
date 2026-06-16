# Integration test stub for gcp-account-vpc-service-controls module.
# Requires:
# - GCP organization with VPC Service Controls enabled
# - Service account with roles/accesscontextmanager.policyAdmin
# - Existing Access Context Manager access policy
# - At least one GCP project number to protect
#
# Set environment variables:
#   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account-key.json
#   export TF_VAR_access_policy_id=<your-policy-id>
#   export TF_VAR_protected_project_numbers='["<project-number>"]'
#
# Run: terraform test -filter=tests/integration.tftest.hcl

variables {
  access_policy_id          = ""
  protected_project_numbers = []
}

run "setup" {
  command = plan

  # Skip if credentials not configured
  # Uncomment when ready to run integration tests
  # module {
  #   source = "../"
  # }
}

# Placeholder for apply-command integration test
# Will be implemented when test environment is configured

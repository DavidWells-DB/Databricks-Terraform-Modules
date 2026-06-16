# integration.tftest.hcl — apply-command tests against a live Databricks workspace
#
# These tests require real credentials and a Premium-tier or higher workspace.
# They are gated by the presence of required environment variables.
#
# Set these environment variables to run integration tests:
# - DATABRICKS_HOST — workspace URL (e.g., https://dbc-12345678-abcd.cloud.databricks.com)
# - DATABRICKS_TOKEN — personal access token or service principal token
#
# Run with: terraform test
#
# The test will skip if credentials are not present (per DATABRICKS_RULES.md Rule 4.1).

# Placeholder for apply-command integration tests.
# These tests will:
# 1. Create a SQL warehouse with minimum configuration
# 2. Verify outputs (warehouse_id, jdbc_url, data_source_id)
# 3. Test permissions grants
# 4. Clean up (implicit via test framework)
#
# TODO: Implement when test credentials are wired.
# TODO: Add a test case that verifies tier-failure behavior against a Standard workspace
#       (per DATABRICKS_RULES.md Rule 4.1).

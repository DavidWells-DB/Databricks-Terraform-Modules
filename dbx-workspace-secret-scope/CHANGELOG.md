# Changelog

All notable changes to the `dbx-workspace-secret-scope` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

### Added
- Initial module: creates Databricks secret scopes via `for_each` over a `scopes` map input.
- Support for `initial_manage_principal` per scope (null or `"users"`).
- Support for Azure Key Vault-backed scopes via optional `keyvault_metadata` block (resource_id + dns_name).
- Variable validation on scope names (1-128 chars, alphanumeric/dash/underscore/period) and `initial_manage_principal` (null or "users").
- Outputs: `scope_names` (set), `scope_ids` (map), `scope_backend_types` (map).
- `examples/basic/` — minimum invocation with two Databricks-native scopes.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering resource creation, all variable validations, and multiple-scope for_each.
- `tests/integration.tftest.hcl` — apply-command stub for live Databricks workspace (credential-gated; includes tier-failure case placeholder per DATABRICKS_RULES Rule 4.1).

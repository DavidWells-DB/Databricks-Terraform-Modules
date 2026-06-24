# Changelog

All notable changes to the `dbx-uc-schema` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

## [0.1.0] - 2026-06-23

### Added
- Initial module: creates `databricks_schema` resources via `for_each` with optional `databricks_grants` per schema.
- `schemas` input: map of schema name to configuration object supporting `comment`, `storage_root`, `properties`, and `grants`.
- Variable validation on `catalog_name` (UC naming constraints) and schema names (UC naming constraints).
- Outputs: `schema_ids`, `schema_names`, `schema_storage_roots`, `catalog_name`.
- `examples/basic/` — minimum invocation demonstrating two schemas, one with grants.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering resource attribute assertions, grants conditional logic, and all variable validations.
- `tests/integration.tftest.hcl` — apply-command stub for live Databricks workspace (credential-gated; includes placeholder for the tier-failure case per DATABRICKS_RULES.md Rule 4.1).

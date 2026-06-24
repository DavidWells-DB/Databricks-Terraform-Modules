# Changelog

All notable changes to the `dbx-uc-catalog` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

## [0.1.0] - 2026-06-23

### Added
- Initial module: creates `databricks_catalog` resources via `for_each` with optional `databricks_grants` per catalog.
- `catalogs` input: map of catalog name to configuration object supporting `comment`, `storage_root`, `isolation_mode`, `properties`, and `grants`.
- Variable validation on `metastore_id` (UUID format), catalog names (UC naming constraints), and `isolation_mode` (enumerated values).
- Outputs: `catalog_ids`, `catalog_names`, `catalog_metastore_ids`, `catalog_storage_roots`.
- `examples/basic/` — minimum invocation demonstrating two catalogs, one with grants.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering resource attribute assertions, grants conditional logic, and all variable validations.
- `tests/integration.tftest.hcl` — apply-command stub for live Databricks workspace (credential-gated; includes placeholder for the tier-failure case per DATABRICKS_RULES.md Rule 4.1).

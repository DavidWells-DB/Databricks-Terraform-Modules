# Changelog

All notable changes to the `dbx-uc-metastore` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/)

## [Unreleased]

## [0.1.2] - 2026-11-04

### Fixed — external review finding (Med): null-guard validations broke on Terraform < 1.12
- The `var.x == null || <checks>` validations relied on `||` short-circuiting, which landed in Terraform 1.12.0 (2025-05-14). On earlier versions the RHS evaluated eagerly and errored on null (trimspace/for-expression/attribute access), so a plan with the variable unset failed variable validation. The error-prone RHS is now wrapped in `try(..., true)` — the fallback fires only in the null case, so semantics are identical on every supported version and the `>= 1.7` floor is now honest.


## [0.1.1] - 2026-11-04

### Changed — external review finding (High): metastore force_destroy is now an explicit opt-in
- `force_destroy` was hard-coded `true` on `databricks_metastore`. Destroying a metastore is a region-wide catastrophic action (every catalog/table under it loses its metadata); it is now an input defaulting to `false`. Scratch/journey harnesses pass `force_destroy = true` explicitly.


## [0.1.0] - 2026-06-23

### Changed
- `storage_root_url`, `data_access_name`, and `storage_credential` are now **optional** (default `null`). Omitting them creates a **storageless metastore** (recommended; manage storage at the catalog level). `databricks_metastore_data_access` is created only when `storage_credential` is set, guarded by a precondition that `data_access_name` is supplied. `data_access_id` output returns `null` for storageless metastores. Backward compatible: supplying all three behaves as before.

### Added
- Initial module: creates `databricks_metastore` and `databricks_metastore_data_access` on the account provider surface.
- Cloud-agnostic `storage_credential` object input (aws_iam_role, azure_managed_identity, databricks_gcp_service_account) per the Databricks module rules Rule 2.4.
- Variable validation on `metastore_name` (1-255 chars, no surrounding whitespace), `region` (alphanumeric/hyphen), `storage_root_url` (s3://, abfss://, or gs:// prefix), `data_access_name` (1-255 chars, no surrounding whitespace), `owner_group` (null or non-empty, no surrounding whitespace), and `storage_credential` mutual-exclusivity (exactly one cloud block).
- Outputs: `metastore_id`, `metastore_name`, `data_access_id`.
- `examples/basic/` — minimum invocation against AWS.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering all variable validations and resource attribute assertions.
- `tests/integration.tftest.hcl` — apply-command stub for live Databricks account (credential-gated; includes placeholder for tier-failure case per the Databricks module rules Rule 4.1).

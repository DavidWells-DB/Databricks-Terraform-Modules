# Changelog

All notable changes to the `dbx-uc-metastore` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

## [0.1.0] - 2026-06-23

### Changed
- `storage_root_url`, `data_access_name`, and `storage_credential` are now **optional** (default `null`). Omitting them creates a **storageless metastore** (recommended; manage storage at the catalog level). `databricks_metastore_data_access` is created only when `storage_credential` is set, guarded by a precondition that `data_access_name` is supplied. `data_access_id` output returns `null` for storageless metastores. Backward compatible: supplying all three behaves as before.

### Added
- Initial module: creates `databricks_metastore` and `databricks_metastore_data_access` on the account provider surface.
- Cloud-agnostic `storage_credential` object input (aws_iam_role, azure_managed_identity, databricks_gcp_service_account) per DATABRICKS_RULES.md Rule 2.4.
- Variable validation on `metastore_name` (1-255 chars, no surrounding whitespace), `region` (alphanumeric/hyphen), `storage_root_url` (s3://, abfss://, or gs:// prefix), `data_access_name` (1-255 chars, no surrounding whitespace), `owner_group` (null or non-empty, no surrounding whitespace), and `storage_credential` mutual-exclusivity (exactly one cloud block).
- Outputs: `metastore_id`, `metastore_name`, `data_access_id`.
- `examples/basic/` — minimum invocation against AWS.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering all variable validations and resource attribute assertions.
- `tests/integration.tftest.hcl` — apply-command stub for live Databricks account (credential-gated; includes placeholder for tier-failure case per DATABRICKS_RULES Rule 4.1).

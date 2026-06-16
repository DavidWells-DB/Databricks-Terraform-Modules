# Changelog

All notable changes to the `gcp-uc-storage-credential` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

### Added
- Initial module: creates `databricks_storage_credential` with `databricks_gcp_service_account` block and grants `roles/storage.objectAdmin` + `roles/storage.legacyBucketReader` on the target GCS bucket.
- Variable validation on `credential_name` (1-100 chars, alphanumeric/underscore/hyphen) and `bucket_name` (GCS naming constraints).
- Outputs: `storage_credential_id`, `databricks_service_account_email`, `storage_credential_name`.
- `examples/basic/` — minimum invocation against a GCP project with an existing GCS bucket.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering resource attributes and all variable validations.
- `tests/integration.tftest.hcl` — apply-command stub for live GCP + Databricks workspace (credential-gated; includes a placeholder for the tier-failure case per DATABRICKS_RULES Rule 4.1).

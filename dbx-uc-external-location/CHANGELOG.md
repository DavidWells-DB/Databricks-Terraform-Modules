# Changelog

All notable changes to the `dbx-uc-external-location` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

## [0.1.0] - 2026-06-23

### Added
- Initial module: registers cloud storage paths as Unity Catalog external locations via `databricks_external_location` (for_each).
- Optional per-location `databricks_grants` with `dynamic` grant blocks; grant resources are only created when a location's grants map is non-empty.
- Variable validation: location URL scheme (s3://, abfss://, gs://), location name character set, non-empty `storage_credential_id`.
- Outputs: `external_location_ids`, `external_location_names`, `external_location_urls` (all as maps keyed by location name).
- `examples/basic/` — minimum invocation with two locations (one S3, one GCS) and sample grants.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering attribute checks, default values, grant inclusion/omission, and all variable validations.
- `tests/integration.tftest.hcl` — apply-command stub for live Databricks workspace (credential-gated; includes placeholder for tier-failure case per DATABRICKS_RULES Rule 4.1).

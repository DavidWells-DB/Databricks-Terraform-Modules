# Changelog

All notable changes to the `dbx-uc-external-location` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/)

## [Unreleased]

## [0.2.0] - 2026-11-04

### Fixed — external review finding (High): credential NAME vs UUID wiring
- `locations.*.storage_credential_id` renamed to `storage_credential_name`: the provider's
  `credential_name` field takes the credential NAME, but the old field was documented and
  consumed as the UUID id (the credential modules' `storage_credential_id` output), so every
  external location created through this module was wired to a non-existent credential.
  Callers must now pass `storage_credential_name` (the `storage_credential_name` output of
  the `*-uc-storage-credential` modules). The plan test that asserted the wrong mapping is
  corrected.


## [0.1.0] - 2026-06-23

### Added
- Initial module: registers cloud storage paths as Unity Catalog external locations via `databricks_external_location` (for_each).
- Optional per-location `databricks_grants` with `dynamic` grant blocks; grant resources are only created when a location's grants map is non-empty.
- Variable validation: location URL scheme (s3://, abfss://, gs://), location name character set, non-empty `storage_credential_id`.
- Outputs: `external_location_ids`, `external_location_names`, `external_location_urls` (all as maps keyed by location name).
- `examples/basic/` — minimum invocation with two locations (one S3, one GCS) and sample grants.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering attribute checks, default values, grant inclusion/omission, and all variable validations.
- `tests/integration.tftest.hcl` — apply-command stub for live Databricks workspace (credential-gated; includes placeholder for tier-failure case per the Databricks module rules Rule 4.1).

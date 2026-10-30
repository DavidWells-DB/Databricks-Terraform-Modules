# Changelog

All notable changes to the `gcp-uc-storage-bucket` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/)

## [Unreleased]

## [0.1.0] - 2026-10-30

### Added
- Initial module: creates a dedicated GCS bucket for a Unity Catalog catalog's managed storage (best practice: catalog data on its own bucket, not the workspace root the platform's workspace catalog shares). Uniform bucket-level access + public-access prevention enforced; access flows via the storage credential's Databricks-managed service account.
- Outputs `bucket_name`, `storage_root` (the `gs://<bucket>` UC root — the composition appends any path suffix).
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering defaults, access posture, and variable validations.

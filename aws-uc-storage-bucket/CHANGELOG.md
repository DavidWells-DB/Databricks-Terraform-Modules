# Changelog

All notable changes to the `aws-uc-storage-bucket` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/)

## [Unreleased]

## [0.1.0] - 2026-10-30

### Added
- Initial module: creates a dedicated S3 bucket for a Unity Catalog catalog's managed storage (best practice: catalog data on its own bucket, not the workspace root the platform's workspace catalog shares). SSE-S3 by default, KMS optional; all four public-access blocks on; no DBFS-root bucket policy (not workspace-registration storage).
- Outputs `bucket_name`, `bucket_arn`, `storage_root` (the `s3://<bucket>` UC root — the composition appends any path suffix).
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering defaults, KMS branching, public-access posture, and variable validations.

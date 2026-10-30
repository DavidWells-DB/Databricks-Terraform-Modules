# Changelog

All notable changes to the `azure-uc-storage-bucket` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/)

## [Unreleased]

## [0.1.0] - 2026-10-30

### Added
- Initial module: creates a dedicated ADLS Gen2 storage account (HNS-enabled, private, HTTPS-only) + private container for a Unity Catalog catalog's managed storage (best practice: catalog data on its own container, not the workspace root storage the platform's workspace catalog shares).
- Outputs `storage_account_id` (feeds azure-uc-storage-credential), `storage_account_name`, `container_name`, `storage_root` (the `abfss://…dfs.core.windows.net` UC root).
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering the ADLS posture, defaults, and naming validations.

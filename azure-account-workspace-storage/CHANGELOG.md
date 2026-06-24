# Changelog

All notable changes to the `azure-account-workspace-storage` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

## [0.1.0] - 2026-06-23

### Added
- Initial module: creates ADLS Gen2 storage account (`azurerm_storage_account`) and container (`azurerm_storage_container`) for UC metastore storage or workspace root storage.
- Hierarchical namespace (`is_hns_enabled = true`) enabled by default; required for ADLS Gen2.
- HTTPS-only and TLS 1.2 enforced by default; public blob access disabled.
- Optional customer-managed key (CMK) support via `kms_key_id` input; required for Azure Government IL5.
- Variable validation on `resource_prefix` (Azure storage account name constraints), `container_name` (Azure container name constraints), `account_tier`, `account_replication_type`, and `min_tls_version`.
- Outputs: `storage_account_name`, `storage_account_id`, `container_name`, `dfs_endpoint`, `primary_blob_endpoint`, `storage_account_principal_id`.
- `examples/basic/` — minimum invocation showing ADLS Gen2 creation for a Databricks UC metastore.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering variable validations and resource attribute checks.
- `tests/integration.tftest.hcl` — apply-command stub for live Azure (credential-gated).

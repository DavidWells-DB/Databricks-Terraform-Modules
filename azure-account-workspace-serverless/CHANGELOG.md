# Changelog

All notable changes to the `azure-account-workspace-serverless` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

## [0.1.0] - 2026-06-23

### Added
- Initial module: creates Azure Databricks workspace without VNet injection for serverless compute.
- `azurerm_databricks_workspace` resource with no `custom_parameters` block (serverless pattern).
- Optional `azurerm_databricks_workspace_root_dbfs_customer_managed_key` resource (post-creation CMK step).
- Variable validation on `name` (Azure resource name constraints: 3-64 chars, alphanumeric + hyphens) and `sku` (enumerated values).
- Optional CMK inputs: `managed_services_cmk_key_vault_key_id`, `managed_disk_cmk_key_vault_key_id`, `root_dbfs_cmk_key_vault_key_id`.
- Optional storage firewall inputs: `default_storage_firewall_enabled`, `access_connector_id`.
- Outputs: `workspace_id`, `workspace_url`, `workspace_resource_id`, `managed_resource_group_id`, `storage_account_identity`, `managed_disk_identity`, `disk_encryption_set_id`.
- `examples/basic/` — minimum invocation against a commercial Azure subscription.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering variable validations, resource attribute checks, and CMK conditional logic.
- `tests/integration.tftest.hcl` — apply-command stub for live Azure (credential-gated; includes tier-failure case per DATABRICKS_RULES Rule 4.1).

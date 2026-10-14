# Changelog

All notable changes to the `azure-account-workspace-serverless` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per the module rules Rule 5.1.

## [Unreleased]

## [1.0.1] - 2026-10-14

### Added
- `compute_mode` output — the deployed ARM `properties.computeMode` (`"Serverless"`), from the same `response_export_values` path. Lets roots/journeys verify the deployed workspace type post-apply without an out-of-band `az show`. (Mocked plan tests cannot materialize azapi's dynamic `output` attribute, so this is asserted in the integration test and by live journeys.)


## [1.0.0] - 2026-10-13

### Fixed — BREAKING (corrective)
- **The module now creates an actual serverless workspace.** v0.1.0 deployed a Classic (managed-VNet / `computeMode = "Hybrid"`) workspace despite the module name and README: `azurerm_databricks_workspace` has no `computeMode` argument, so "no `custom_parameters` + premium SKU" never made the workspace serverless (reported by external testing — thank you).
- The workspace is now an `azapi_resource` of `Microsoft.Databricks/workspaces@2026-01-01` with `properties.computeMode = "Serverless"` (required on create, immutable after). `azurerm` is no longer a dependency of this module.
- Existing workspaces created by v0.1.0 cannot be adopted: `computeMode` cannot be changed, so they must be recreated.

### Changed (breaking interface)
- `resource_group_name` (bare name) → `resource_group_id` (full ARM ID; azapi's `parent_id`).
- `sku` variable removed — `premium` is hardcoded in the ARM body (the only tier that supports serverless).
- Outputs removed: `managed_resource_group_id`, `storage_account_identity`, `managed_disk_identity`, `disk_encryption_set_id` — none exist in Serverless computeMode (managed default storage, no managed resource group).
- `workspace_id` is now a string (ARM exports it as a string; azurerm returned a number).

### Removed
- Variables for properties the Serverless computeMode forbids (ARM rejects them at create): `managed_resource_group_name`, `access_connector_id`, `default_storage_firewall_enabled`, `managed_disk_cmk_key_vault_key_id` (+ rotation flag), `root_dbfs_cmk_key_vault_key_id`/`root_dbfs_cmk_key_vault_id` (+ the post-creation root-DBFS CMK resource), `customer_managed_key_enabled`, `infrastructure_encryption_enabled`.

### Added
- `managed_services_cmk_key_vault_key_id` now carries the CMK alone (managed services is the only legal customer-managed key in Serverless mode) and is parsed into the ARM `keyName`/`keyVaultUri`/`keyVersion` triple; validation requires a versioned key identifier.
- `response_export_values` exports `computeMode` so tests assert the deployed workspace type.
- Plan tests assert `body.properties.computeMode == "Serverless"`, the pinned `@2026-01-01` API version, and the key-ID parsing; the integration test asserts the live workspace reports `computeMode == "Serverless"`.


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
- `tests/integration.tftest.hcl` — apply-command stub for live Azure (credential-gated; includes tier-failure case per the Databricks module rules Rule 4.1).

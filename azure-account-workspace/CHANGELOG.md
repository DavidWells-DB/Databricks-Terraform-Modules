# Changelog

All notable changes to the `azure-account-workspace` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/)

## [Unreleased]

## [0.2.0] - 2026-10-30

### Changed — BREAKING for existing state (see Migration)
- Workspace creation moved from `azurerm_databricks_workspace` to `azapi_resource` (`Microsoft.Databricks/workspaces@2026-01-01`). Reason: the ARM `properties.defaultCatalog.initialType` field — which makes the platform provision a Unity Catalog workspace catalog (named after the workspace) and set it as the workspace default catalog — exists only in the create request and is not exposed by azurerm at all. Every azurerm-created workspace therefore ships with its default namespace pointing at the legacy `hive_metastore` catalog. The azapi body now sends `defaultCatalog.initialType = "UnityCatalog"`.
- All azurerm workspace-argument semantics carried over 1:1 (verified against azurerm's `r_create.go`/`r_expand.go`): `computeMode = "Hybrid"`, `managedResourceGroupId` (default name `databricks-rg-<resource-group-name>`, azurerm's own fallback), wrapped `{type, value}` custom parameters for VNet injection / `prepareEncryption` / `requireInfrastructureEncryption`, `encryption.entities.managedServices`/`managedDisk` built from the same versioned key-id parsing, `enhancedSecurityCompliance` values as ARM `Enabled`/`Disabled` enums, `publicNetworkAccess`, `requiredNsgRules`, `defaultStorageFirewall` + `accessConnector`.
- azurerm's create-time validations mirrored as plan-time `lifecycle.precondition`s on the azapi resource: VNet-injection input completeness, CSP-forces-ESM+ACU, premium-tier requirement for CMK/ESC/firewall features, managed-services CMK requires `customer_managed_key_enabled`.
- `compute_mode` output now read from the create resource's `response_export_values` (the separate `azapi_resource` data-source readback is gone).
- CMK key-id variables (`managed_services_cmk_key_vault_key_id`, `managed_disk_cmk_key_vault_key_id`) now REQUIRE the versioned key id — azurerm enforced this internally; it is a plan-time error here with a clear message.

### Added
- `is_uc_enabled` output — the deployed ARM `properties.isUcEnabled`, the in-module oracle that the UC/workspace-catalog posture took effect.
- `access_connector_identity_type` / `access_connector_user_assigned_identity_id` variables — azurerm looked the connector's identity type up via API; azapi cannot, so it is an explicit input (default `SystemAssigned`).

### Migration (existing deployments)
The creation resource type changed (`azurerm_databricks_workspace` → `azapi_resource`), which Terraform cannot express as a move. Workspaces deployed with v0.1.x that upgrade to v0.2.0 will plan a full workspace replacement unless the state is migrated:
1. `terraform state rm azurerm_databricks_workspace.this` (inside this module's instance),
2. `terraform import 'module.<name>.azapi_resource.this' /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Databricks/workspaces/<name>`,
3. re-apply — expect an in-place no-op apart from the new `defaultCatalog` readback fields.
Note the platform does NOT retroactively create a workspace catalog for an existing workspace: `defaultCatalog` is honored at creation only. Existing workspaces keep their current default catalog (set it separately via `dbx-uc-metastore-assignment`'s `default_catalog_name`). New workspaces created by v0.2.0 get the workspace catalog from Day-1.

## [0.1.1] - 2026-10-14

### Added
- `compute_mode` output — the deployed ARM `properties.computeMode` (`"Hybrid"` for this module's classic workspace), read back via an `azapi_resource` data source on every plan/apply. azurerm cannot see this field at all, so this is the only in-Terraform way for consumers to verify the deployed workspace type; asserted in the integration test. (Mocked plan runs cannot materialize azapi's dynamic `output`, so no plan-test assertion.)

### Changed
- azapi provider floor `>= 1.9` → `>= 2.0` (honest pin: the compliance `azapi_update_resource` already used the 2.x object-style body; the new data source's `response_export_values` map form is 2.x-only).


## [0.1.0] - 2026-06-23

### Added
- Initial module: creates Azure Databricks workspace via `azurerm_databricks_workspace`.
- Optional VNet injection via `virtual_network_id`, `host_subnet_name`, `container_subnet_name`, and NSG association inputs.
- Optional root DBFS CMK via `azurerm_databricks_workspace_root_dbfs_customer_managed_key` (post-creation).
- Compliance security profile support: `azurerm`-native standards (`HIPAA`, `PCI_DSS`, `NONE`) and extended standards (`HITRUST`, `IRAP_PROTECTED`, `UK_CYBER_ESSENTIALS_PLUS`, `CANADA_PROTECTED_B`) via `azapi_update_resource`.
- `ignore_changes` on `enhanced_security_compliance[0].compliance_security_profile_standards` to prevent `azurerm` from reverting standards applied by `azapi_update_resource`.
- Variable validation on `sku`, `network_security_group_rules_required`, `compliance_security_profile_standards`, and `extended_compliance_standards`.
- Outputs: `workspace_id`, `workspace_url`, `workspace_resource_id`, `managed_resource_group_id`, `storage_account_identity`, `managed_disk_identity`, `disk_encryption_set_id`.
- `examples/basic/` — minimum invocation of a premium workspace without VNet injection.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering conditional logic and all variable validations.
- `tests/integration.tftest.hcl` — apply-command stub for live Azure + Databricks (credential-gated; includes tier-failure case placeholder per the Databricks module rules Rule 4.1).

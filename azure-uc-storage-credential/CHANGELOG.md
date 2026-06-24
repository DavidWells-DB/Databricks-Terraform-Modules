# Changelog

All notable changes to the `azure-uc-storage-credential` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

## [0.1.0] - 2026-06-23

### Added
- Initial module: creates Azure Databricks Access Connector (SystemAssigned managed identity) + `azurerm_role_assignment` (Storage Blob Data Contributor) + `databricks_storage_credential` UC registration.
- `access_connector_name` optional input with auto-derived default (`dbx-access-connector-<credential_name>`).
- `skip_validation` input for locked-down VNet environments where Databricks credential validation cannot complete.
- Variable validation on `resource_group_name` (Azure naming constraints), `location` (lowercase alphanumeric), `storage_account_id` (fully-qualified ARM resource ID pattern), and `credential_name` (conservative alphanumeric + hyphen + underscore bounds).
- Outputs: `access_connector_id`, `access_connector_principal_id`, `storage_credential_id`, `storage_credential_name`.
- `examples/basic/` — minimum invocation against an Azure subscription.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering name derivation, explicit override, and all variable validations.
- `tests/integration.tftest.hcl` — apply-command stub for live Azure + Databricks (credential-gated; includes a placeholder for the tier-failure case per DATABRICKS_RULES Rule 4.1).

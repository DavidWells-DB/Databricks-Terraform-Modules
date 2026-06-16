# Changelog

All notable changes to the `azure-account-encryption-keys` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

### Added
- Initial module: creates Azure Key Vault (Premium SKU, purge protection enabled) with three RSA-2048 CMK keys (managed services, workspace storage, managed disk).
- `azurerm_key_vault_access_policy` for Terraform operator (full key management) and Databricks first-party service principal (Get, WrapKey, UnwrapKey).
- Optional private endpoint with private DNS zone and VNet link via `private_endpoint` input object.
- Variable validation on `key_vault_name` (Azure naming constraints), `tenant_id`, `databricks_service_principal_object_id`, `azure_client_object_id` (UUID format), and `soft_delete_retention_days` (7-90 range).
- `locals.tf`: `pe_resource_group_name` fallback to module-level resource group when private endpoint RG not specified.
- Outputs: `key_vault_id`, `key_vault_name`, `key_vault_uri`, `managed_services_key_id`, `managed_services_key_versionless_id`, `workspace_storage_key_id`, `workspace_storage_key_versionless_id`, `managed_disk_key_id`, `managed_disk_key_versionless_id`, `private_endpoint_id`.
- `examples/basic/` — minimum invocation without private endpoint.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering all variable validations and conditional private endpoint logic.
- `tests/integration.tftest.hcl` — apply-command stub for live Azure (credential-gated; includes placeholder for tier-failure case per DATABRICKS_RULES Rule 4.1).

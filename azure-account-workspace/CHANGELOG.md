# Changelog

All notable changes to the `azure-account-workspace` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

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
- `tests/integration.tftest.hcl` — apply-command stub for live Azure + Databricks (credential-gated; includes tier-failure case placeholder per DATABRICKS_RULES Rule 4.1).

# Changelog

All notable changes to the `dbx-workspace-compliance-settings` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

### Added
- Initial module: applies workspace-level compliance hardening via five workspace settings resources.
- `databricks_compliance_security_profile_workspace_setting`: enables CSP with configurable compliance standards (HIPAA, FedRAMP, PCI-DSS, and 11 other standards). Permanent once enabled.
- `databricks_enhanced_security_monitoring_workspace_setting`: enables ESM independently or alongside CSP.
- `databricks_automatic_cluster_update_workspace_setting`: enables automatic cluster patching with optional week-day-based maintenance window.
- `databricks_disable_legacy_access_setting`: disables direct Hive Metastore access, external location fallback, and runtimes < 13.3 LTS.
- `databricks_disable_legacy_dbfs_setting`: disables root DBFS for new workloads.
- Variable validation on `compliance_standards` (enumerated allow-list), maintenance window `day_of_week`, `frequency`, `hours` (0–23), and `minutes` (0–59).
- Outputs: feature-flag booleans and `compliance_standards` for downstream consumption.
- `examples/basic/` — minimum invocation enabling CSP + ESM + legacy access/DBFS controls.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering all variable validations and conditional resource creation logic.
- `tests/integration.tftest.hcl` — apply-command stub for live Databricks workspace (credential-gated; includes tier-failure case per DATABRICKS_RULES Rule 4.1).

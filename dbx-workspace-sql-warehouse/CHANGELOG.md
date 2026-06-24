# Changelog

All notable changes to the `dbx-workspace-sql-warehouse` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

## [0.1.0] - 2026-06-23

### Added
- Initial module: creates Databricks SQL warehouse (endpoint) with `databricks_sql_endpoint` and optional `databricks_permissions`.
- Variable validation on `cluster_size` (9 allowed values), `warehouse_type` (CLASSIC/PRO), `spot_instance_policy` (3 allowed values), `channel` (CURRENT/PREVIEW), `auto_stop_mins` (>= 0), `min_num_clusters` (>= 1), `max_num_clusters` (>= 1), `permissions` (valid permission levels).
- Lifecycle precondition ensuring `max_num_clusters >= min_num_clusters`.
- Principal type inference for permissions: UUID → service principal, contains @ → user, else → group.
- Outputs: `warehouse_id`, `warehouse_name`, `jdbc_url`, `odbc_params`, `data_source_id`.
- `examples/basic/` — minimum invocation with a small PRO warehouse.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering all variable validations and preconditions.
- `tests/integration.tftest.hcl` — apply-command stub for live Databricks workspace (credential-gated; includes a placeholder for the tier-failure case per DATABRICKS_RULES Rule 4.1).

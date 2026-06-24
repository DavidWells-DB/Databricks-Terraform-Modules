# Changelog

All notable changes to the `dbx-uc-metastore-assignment` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

## [0.1.0] - 2026-06-23

### Added
- Initial module: assigns a Unity Catalog metastore to one or more workspaces via `databricks_metastore_assignment` (for_each over `workspace_ids` map).
- Optional `databricks_default_namespace_setting` for setting the default catalog on the workspace targeted by the `databricks.workspace` provider alias.
- Variable validation on `metastore_id` (UUID format), `workspace_ids` (non-empty, numeric values), and `default_catalog_name` (no leading/trailing whitespace).
- Outputs: `assignment_ids`, `assigned_workspace_ids`, `metastore_id`, `default_catalog_name`.
- `examples/basic/` — minimum invocation assigning a metastore to two workspaces without a default catalog.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering resource attribute checks and all variable validations.
- `tests/integration.tftest.hcl` — apply-command stub for live Databricks account + workspace (credential-gated; includes a placeholder for the tier-failure case per DATABRICKS_RULES Rule 4.1).

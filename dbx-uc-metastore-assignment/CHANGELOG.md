# Changelog

All notable changes to the `dbx-uc-metastore-assignment` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

## [0.2.0] - 2026-08-04

### Changed
- **`metastore_id` is now OPTIONAL (default `null`), and an empty `workspace_ids` map is valid.** Databricks **auto-assigns the region's DEFAULT Unity Catalog metastore** to a new workspace, so an explicit `databricks_metastore_assignment` is unnecessary in the normal case (verified 2026-08-04: a workspace nobody had explicitly assigned already carried its region's default). An explicit assignment is only needed to *override* that — e.g. multiple metastores in the region with no default configured, or binding a non-default metastore. With `metastore_id = null` + `workspace_ids = {}` the module creates **no assignment**, while `default_catalog_name` continues to work independently (it is a separate, workspace-scoped resource).
- Removed the blanket `workspace_ids must contain at least one entry` validation, which contradicted the optional-metastore case. Replaced with a **coherence validation**: `metastore_id` and `workspace_ids` must be set together — supplying one without the other silently did nothing before, and now fails loudly.

### Fixed
- `metastore_id` UUID validation now also accepts uppercase hex and is skipped when null.

12/12 plan tests pass, including the new `null_metastore_creates_no_assignment` and `metastore_without_workspaces_rejected` cases.

## [0.1.0] - 2026-06-23

### Added
- Initial module: assigns a Unity Catalog metastore to one or more workspaces via `databricks_metastore_assignment` (for_each over `workspace_ids` map).
- Optional `databricks_default_namespace_setting` for setting the default catalog on the workspace targeted by the `databricks.workspace` provider alias.
- Variable validation on `metastore_id` (UUID format), `workspace_ids` (non-empty, numeric values), and `default_catalog_name` (no leading/trailing whitespace).
- Outputs: `assignment_ids`, `assigned_workspace_ids`, `metastore_id`, `default_catalog_name`.
- `examples/basic/` — minimum invocation assigning a metastore to two workspaces without a default catalog.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering resource attribute checks and all variable validations.
- `tests/integration.tftest.hcl` — apply-command stub for live Databricks account + workspace (credential-gated; includes a placeholder for the tier-failure case per DATABRICKS_RULES Rule 4.1).

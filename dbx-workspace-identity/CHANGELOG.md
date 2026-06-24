# Changelog

All notable changes to the `dbx-workspace-identity` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

## [0.1.0] - 2026-06-23

### Added
- Initial module: assigns account-level principals to a workspace via `databricks_mws_permission_assignment` with `for_each`.
- Variable validation on `assignments`: at least one role per entry; roles must be "USER" or "ADMIN".
- `time_sleep` (20s) for workspace permission API readiness after workspace creation, per DATABRICKS_RULES.md Rule 3.1.
- `ignore_changes = [principal_id]` on all assignments, per DATABRICKS_RULES.md Rule 3.2 (SCIM/AIM IdP sync resistance).
- Output: `assignment_ids` map keyed by assignment label.
- `examples/basic/` — minimum invocation showing a group and a service principal assigned to a workspace.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering happy path, validation failures (empty roles, invalid role values).
- `tests/integration.tftest.hcl` — apply-command stub for live Databricks account (credential-gated; includes placeholder for tier-failure case per DATABRICKS_RULES Rule 4.1).

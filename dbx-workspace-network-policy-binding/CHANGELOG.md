# Changelog

All notable changes to the `dbx-workspace-network-policy-binding` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

## [0.1.0] - 2026-08-02

### Added
- Initial module: binds a standalone account network policy to a workspace via `databricks_workspace_network_option` — without requiring an NCC. Fills the gap (open-item E5) where the only binding path, `dbx-workspace-network-serverless`, coupled the binding to an NCC (a Secure+ feature), forcing blueprints to compose the raw resource as root glue.
- `databricks_workspace_network_option` wired to the account provider surface (open-item E8: it is account-surface; a workspace provider fails with "Not Found").
- `time_sleep.unbind_settle` destroy-ordering guard (open-item E12): inserts a configurable settle delay between the binding destroy and a dependent policy delete, eliminating the "failed to delete account_network_policy" retry-on-destroy.
- Variable validation on `network_policy_id` (non-empty) and `unbind_settle_duration` (Go duration format).
- Outputs: `binding_id` (composite `<workspace_id>|<network_policy_id>`, since the resource exports no id), `workspace_id`, `network_policy_id`.
- `examples/basic/` — minimum invocation binding a policy to a workspace.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering binding wiring, the default-policy case, the destroy-ordering guard, and all variable validations.
- `tests/integration.tftest.hcl` — apply-command stub for a live Databricks account + workspace (credential-gated).

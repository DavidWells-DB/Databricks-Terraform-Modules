# Changelog

All notable changes to the `dbx-workspace-ip-access-list` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

### Added
- Initial module: enables IP access list enforcement via `databricks_workspace_conf` and creates a required ALLOW list plus an optional BLOCK list via `databricks_ip_access_list`.
- Variable validation on `allow_list_cidrs` (non-empty, basic IPv4/CIDR format), `block_list_cidrs` (optional; same format check), and label length bounds.
- Outputs: `allow_list_id`, `allow_list_label`, `block_list_id` (null when no block list), `workspace_conf_id`.
- `examples/basic/` — minimum invocation with allow list only and a combined allow+block example.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering allow-only, allow+block, and all variable validations.
- `tests/integration.tftest.hcl` — apply-command stub for live Databricks workspace (credential-gated; includes tier-failure stub per DATABRICKS_RULES Rule 4.1).

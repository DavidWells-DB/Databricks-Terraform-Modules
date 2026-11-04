# Changelog

All notable changes to the `dbx-workspace-ip-access-list` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/)

## [Unreleased]

## [0.1.1] - 2026-11-04

### Fixed — external review finding (Med): null-guard validations broke on Terraform < 1.12
- The `var.x == null || <checks>` validations relied on `||` short-circuiting, which landed in Terraform 1.12.0 (2025-05-14). On earlier versions the RHS evaluated eagerly and errored on null (trimspace/for-expression/attribute access), so a plan with the variable unset failed variable validation. The error-prone RHS is now wrapped in `try(..., true)` — the fallback fires only in the null case, so semantics are identical on every supported version and the `>= 1.7` floor is now honest.


## [0.1.0] - 2026-06-23

### Added
- Initial module: enables IP access list enforcement via `databricks_workspace_conf` and creates a required ALLOW list plus an optional BLOCK list via `databricks_ip_access_list`.
- Variable validation on `allow_list_cidrs` (non-empty, basic IPv4/CIDR format), `block_list_cidrs` (optional; same format check), and label length bounds.
- Outputs: `allow_list_id`, `allow_list_label`, `block_list_id` (null when no block list), `workspace_conf_id`.
- `examples/basic/` — minimum invocation with allow list only and a combined allow+block example.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering allow-only, allow+block, and all variable validations.
- `tests/integration.tftest.hcl` — apply-command stub for live Databricks workspace (credential-gated; includes tier-failure stub per the Databricks module rules Rule 4.1).

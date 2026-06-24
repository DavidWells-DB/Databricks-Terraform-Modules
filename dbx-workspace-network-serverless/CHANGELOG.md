# Changelog

All notable changes to the `dbx-workspace-network-serverless` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

## [0.1.0] - 2026-06-23

### Added
- Initial module: binds a Network Connectivity Config (NCC) to a workspace via `databricks_mws_ncc_binding`.
- Private endpoint rules via `databricks_mws_ncc_private_endpoint_rule` with `for_each` over a unified `private_endpoint_rules` list (cloud-agnostic input shape covering both AWS and Azure fields).
- Optional network policy assignment via `databricks_workspace_network_option` (created only when `network_policy_id` is non-null).
- Variable validation on `network_connectivity_config_id` (UUID format) and `private_endpoint_rules` (unique keys).
- Outputs: `ncc_binding_id`, `network_connectivity_config_id`, `workspace_id`, `private_endpoint_rule_ids`, `network_policy_id`.
- `examples/basic/` — minimum invocation binding an NCC to a workspace without PE rules or network policy.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering NCC binding, PE rule `for_each`, conditional `workspace_network_option`, and all variable validations.
- `tests/integration.tftest.hcl` — apply-command stub for live Databricks account + workspace (credential-gated; includes a placeholder for the tier-failure case per DATABRICKS_RULES Rule 4.1).

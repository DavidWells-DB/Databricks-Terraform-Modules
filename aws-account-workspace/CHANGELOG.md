# Changelog

All notable changes to the `aws-account-workspace` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

## [0.1.0] - 2026-06-23

### Added
- Initial module: creates `databricks_mws_workspaces` wiring credentials, storage, network, and optional PrivateLink/CMK/NCC inputs.
- GovCloud parameterization via `databricks_gov_shard` input (commercial, civilian, dod) driving computed account host URL.
- Variable validation on `workspace_name` (3-64 chars, alphanumeric + hyphen + underscore), `region` (standard AWS region pattern), and `databricks_gov_shard` (enumerated values).
- `time_sleep` (30s) for DNS propagation after workspace creation, with `dns_propagation_complete` output as a dependency signal.
- Conditional `databricks_mws_ncc_binding` resource created only when `network_connectivity_config_id` is provided.
- `lifecycle { ignore_changes = [custom_tags] }` on `databricks_mws_workspaces` per DATABRICKS_RULES.md Rule 3.2.
- Outputs: `workspace_id`, `workspace_url`, `workspace_host`, `deployment_name`, `dns_propagation_complete`, `databricks_host`.
- `examples/basic/` — minimum invocation against commercial AWS.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering gov_shard branching, variable validations, and NCC conditional logic.
- `tests/integration.tftest.hcl` — apply-command stub for live Databricks Premium account (credential-gated; includes a placeholder for the tier-failure case per DATABRICKS_RULES Rule 4.1).

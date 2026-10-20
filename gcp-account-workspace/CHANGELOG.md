# Changelog

All notable changes to the `gcp-account-workspace` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/)

## [Unreleased]

## [0.2.0] - 2026-10-20

### Fixed
- No longer requests a custom `deployment_name` at create — the GCP platform assigns its own (`<workspace-id>.9`) and ignores the request, which made every fresh deployment's first re-plan show an output-only drift (an E11-class false positive caught by the acceptance matrix's idempotency gate, live 2026-10-20). The `deployment_name` output remains the readback of the real platform value.

## [0.1.0] - 2026-06-23

### Added
- Initial module: creates `databricks_mws_workspaces` on GCP wiring pre-created network and storage configurations.
- Inputs: `databricks_account_id`, `workspace_name`, `project_id`, `region`, `resource_prefix`, `storage_configuration_id`, `databricks_network_id`, optional `private_access_settings_id`, `managed_services_key_id`, `workspace_storage_key_id`, `custom_tags`.
- Variable validation on `databricks_account_id` (UUID), `workspace_name` (3-64 chars, alphanumeric/hyphen/underscore), `project_id` (GCP format), `region` (GCP format), `resource_prefix` (GCP naming constraints).
- `time_sleep` (30s) for DNS propagation after workspace creation before downstream workspace providers connect.
- `lifecycle { ignore_changes = [custom_tags] }` to prevent plan noise from tags modified via Databricks UI.
- Outputs: `workspace_id`, `workspace_url`, `workspace_host`, `deployment_name`, `dns_propagation_complete`.
- `examples/basic/` — minimum invocation against a GCP project.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering variable validations and resource attribute checks.
- `tests/integration.tftest.hcl` — apply-command stub for live GCP + Databricks (credential-gated; includes placeholder for tier-failure case per the Databricks module rules Rule 4.1).

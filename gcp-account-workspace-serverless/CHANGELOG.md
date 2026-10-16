# Changelog

All notable changes to the `gcp-account-workspace-serverless` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/)

## [Unreleased]

## [0.1.1] - 2026-10-16

### Added
- `compute_mode` output — deployed-type readback (`"SERVERLESS"`) from `databricks_mws_workspaces.compute_mode`, the same detection pattern as the aws/azure serverless modules. Lets roots and the acceptance harness verify the deployed workspace type post-apply.


## [0.1.0] - 2026-06-23

### Added
- Initial module: creates a serverless-only Databricks workspace on GCP via `databricks_mws_workspaces` with `compute_mode = "SERVERLESS"`.
- No VPC, storage configuration, or GKE config required — Databricks manages all compute infrastructure.
- Variable validation on `databricks_account_id` (UUID format), `project_id` (GCP project ID constraints), `region` (GCP region pattern), `resource_prefix` (lowercase alphanumeric + hyphen, 1-20 chars), `workspace_name` (3-64 chars, alphanumeric + hyphen + underscore).
- Optional `managed_services_key_id` for CMK encryption of notebooks and secrets.
- `time_sleep` (30s) for DNS propagation after workspace creation; `dns_propagation_complete` output for root composition dependency ordering.
- `ignore_changes` on `custom_tags` per the Databricks module rules Rule 3.2.
- Outputs: `workspace_id`, `workspace_url`, `workspace_host`, `deployment_name`, `dns_propagation_complete`.
- `examples/basic/` — minimum invocation against a GCP project.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering all variable validations and resource attribute checks.
- `tests/integration.tftest.hcl` — apply-command stub for live GCP + Databricks (credential-gated; includes a placeholder for the tier-failure case per the Databricks module rules Rule 4.1).

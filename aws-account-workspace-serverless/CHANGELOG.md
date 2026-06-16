# Changelog

All notable changes to the `aws-account-workspace-serverless` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

### Added
- Initial module: creates a serverless-only Databricks workspace (`compute_mode = "SERVERLESS"`) with no classic compute plane, no customer VPC, and no IAM credentials required.
- GovCloud parameterization via `databricks_gov_shard` input (commercial, civilian, dod); drives computed `databricks_account_host` local and output.
- Variable validation on `workspace_name` (1-64 chars, alphanumeric/underscore/hyphen), `region` (AWS region format), and `databricks_gov_shard` (enumerated values).
- Optional `managed_services_key_id` input for control-plane CMK encryption of notebooks and secrets.
- Optional `network_connectivity_config_id` input; creates `databricks_mws_ncc_binding` when supplied.
- Optional `deployment_name` and `custom_tags` inputs.
- `lifecycle { ignore_changes = [custom_tags] }` to tolerate human-driven tag modifications outside Terraform.
- Outputs: `workspace_id`, `workspace_url`, `workspace_host`, `workspace_status`, `workspace_status_message`, `databricks_account_host`, `ncc_binding_id`.
- `examples/basic/` — minimum invocation against commercial AWS.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering gov_shard branching, variable validations, and NCC conditional logic.
- `tests/integration.tftest.hcl` — apply-command stub for live Databricks account (credential-gated; includes placeholder for tier-failure case per DATABRICKS_RULES Rule 4.1).

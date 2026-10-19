# Changelog

All notable changes to the `aws-account-workspace-serverless` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/)

## [Unreleased]

## [0.4.0] - 2026-10-19

### Removed (mechanism corrected — the definitive answer)
- `managed_services_key_id` input removed, this time for the right reason: **CMK is not applied at the AWS workspace-CREATE level** — the field is invalid in the serverless create body. The documented mechanism (per product + the serverless-workspaces doc): register the KMS key as an account-level key configuration (`use_cases = ["MANAGED_SERVICES"]`), then PATCH the existing workspace's `managed_services_customer_managed_key_id` (takes the Databricks key-configuration ID, NOT the raw KMS ARN) and poll for RUNNING. Enterprise tier required; the managed-services key covers the serverless root storage; `storage_customer_managed_key_id` must not be set for serverless. The module documents the PATCH path in its README; a first-class input returns if/when the provider exposes the post-create update as a resource.

## [0.3.0] - 2026-10-19

### Restored (v0.2.0's removal was a misread)
- `managed_services_key_id` input RESTORED — CMK on serverless workspaces is a real capability (authoritative product correction): the managed-services key covers control-plane data plus serverless default/root storage (job results, SQL results, notebook revisions); workspace-storage/EBS CMKs do not apply to serverless compute. **REQUIRES THE ENTERPRISE TIER** — the v0.2.0 probe's 'Cannot parse request body' rejection was the sandbox account's TIER GATE, not API-level illegality. The input stays with the tier requirement documented.

## [0.2.0] - 2026-10-19

### Removed
- `managed_services_key_id` input — LIVE 2026-10-19 (readiness campaign, rc-aw1 probe): the account API rejects `managed_services_customer_managed_key_id` combined with `compute_mode = "SERVERLESS"` outright ("Cannot parse request body") — identical to the GCP serverless module's finding the same day. CMK is not supported on AWS serverless workspaces at the API level; the input could never work and is removed rather than kept as a footgun.

## [0.1.1] - 2026-10-14

### Added
- `compute_mode` output — the deployed workspace compute mode, refreshed from the account API on every plan/apply. Lets roots assert the deployed workspace type (a value other than `SERVERLESS` would mean the workspace is not what this module promises); asserted by a new plan-test run against the mock.

## [0.1.0] - 2026-06-23

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
- `tests/integration.tftest.hcl` — apply-command stub for live Databricks account (credential-gated; includes placeholder for tier-failure case per the Databricks module rules Rule 4.1).

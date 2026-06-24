# Changelog

All notable changes to the `aws-account-workspace-credentials` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

## [0.1.0] - 2026-06-23

### Added
- Initial module: creates AWS IAM cross-account role + `databricks_mws_credentials`.
- GovCloud parameterization via `databricks_gov_shard` input (commercial, civilian, dod).
- Variable validation on `aws_partition`, `databricks_gov_shard`, `role_name` (AWS IAM constraints), `credentials_name` (conservative bounds).
- `time_sleep` (30s) for IAM propagation before `databricks_mws_credentials` references the role.
- Outputs: `credentials_id`, `role_arn`, `role_name`, `databricks_aws_account_id` (debug).
- `examples/basic/` — minimum invocation against commercial AWS.
- `tests/plan.tftest.hcl` — 11 plan-command cases with `mock_provider` covering gov_shard branching and all variable validations.
- `tests/integration.tftest.hcl` — apply-command stub for live AWS + Databricks (credential-gated; includes a placeholder for the tier-failure case per DATABRICKS_RULES Rule 4.1).

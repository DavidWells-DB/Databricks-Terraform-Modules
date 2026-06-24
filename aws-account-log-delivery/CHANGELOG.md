# Changelog

All notable changes to the `aws-account-log-delivery` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

## [0.1.0] - 2026-06-23

### Added
- Initial module: creates AWS S3 bucket (with public access block, versioning, and bucket policy) + AWS IAM role (log delivery trust policy) + `databricks_mws_credentials` + `databricks_mws_storage_configurations` + `databricks_mws_log_delivery`.
- Support for both `AUDIT_LOGS` and `BILLABLE_USAGE` log types via `log_types` list variable; each type creates one `databricks_mws_log_delivery` configuration via `for_each`.
- GovCloud parameterization via `databricks_gov_shard` input (commercial, civilian, dod) driving IAM trust policy account ID.
- Variable validation on `aws_partition`, `databricks_gov_shard`, `resource_prefix` (length + character set), and `log_types` (allowed values, non-empty).
- `time_sleep` (30s) for IAM propagation before `databricks_mws_credentials` references the role.
- Outputs: `bucket_name`, `bucket_arn`, `role_arn`, `credentials_id`, `storage_configuration_id`, `log_delivery_configuration_ids` (map by log type), `databricks_aws_account_id` (debug/verification).
- `examples/basic/` — minimum invocation against commercial AWS with both log types.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering gov_shard branching, all variable validations, resource naming, and for_each log type logic.
- `tests/integration.tftest.hcl` — apply-command stub for live AWS + Databricks (credential-gated; includes a placeholder for the tier-failure case per DATABRICKS_RULES.md Rule 4.1).

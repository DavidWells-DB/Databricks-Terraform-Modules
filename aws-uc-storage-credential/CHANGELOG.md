# Changelog

All notable changes to the `aws-uc-storage-credential` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

## [0.1.0] - 2026-06-23

### Added
- Initial module: creates AWS IAM role + `databricks_storage_credential` for Unity Catalog storage access.
- GovCloud parameterization via `databricks_gov_shard` input (commercial, civilian, dod) driving the Databricks UC master role ARN in the IAM trust policy.
- Pre-computed IAM role ARN pattern to break the `external_id` circular dependency: `databricks_storage_credential` is created first (`skip_validation = true`) to obtain the `external_id`, then `aws_iam_role` is created with the correct trust policy.
- Variable validation on `aws_partition`, `databricks_gov_shard`, `aws_account_id` (12-digit constraint), `bucket_name` (S3 naming rules), `role_name` (AWS IAM constraints), `credential_name` (conservative bounds), `isolation_mode` (enumerated values).
- `time_sleep` (30s) for IAM propagation after role policy attachment before Databricks validates the trust relationship.
- Outputs: `storage_credential_id`, `storage_credential_name`, `iam_role_arn`, `iam_role_name`, `external_id`, `unity_catalog_iam_arn`.
- `examples/basic/` — minimum invocation against a commercial AWS account and UC workspace.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering gov_shard branching and all variable validations.
- `tests/integration.tftest.hcl` — apply-command stub for live AWS + Databricks UC workspace (credential-gated; includes a placeholder for the tier-failure case per DATABRICKS_RULES Rule 4.1).

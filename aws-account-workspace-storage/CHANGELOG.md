# Changelog

All notable changes to the `aws-account-workspace-storage` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

### Added
- Initial module: creates S3 bucket (versioning, SSE, public-access-block, bucket policy) + `databricks_mws_storage_configurations`.
- GovCloud parameterization via `databricks_gov_shard` input (commercial, civilian, dod).
- SSE-KMS support via optional `kms_key_arn` input; falls back to SSE-S3 (AES-256) when omitted.
- Variable validation on `aws_partition`, `databricks_gov_shard`, `bucket_name` (S3 naming rules), `storage_configuration_name` (conservative bounds).
- `lifecycle { ignore_changes = [policy] }` on `aws_s3_bucket_policy` with documented rationale (Databricks modifies post-creation).
- Outputs: `storage_configuration_id`, `bucket_name`, `bucket_arn`, `bucket_domain_name`, `databricks_aws_account_id` (debug).
- `examples/basic/` — minimum invocation against commercial AWS.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering gov_shard branching, encryption switching, and all variable validations.
- `tests/integration.tftest.hcl` — apply-command stub for live AWS + Databricks (credential-gated; includes a placeholder for the tier-failure case per DATABRICKS_RULES Rule 4.1).

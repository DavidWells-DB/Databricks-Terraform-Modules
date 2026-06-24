# Changelog

All notable changes to the `aws-account-encryption-keys` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/) per TERRAFORM_RULES.md Rule 5.1.

## [Unreleased]

## [0.1.0] - 2026-06-23

### Added
- Initial module: creates two AWS KMS keys (managed-services + workspace-storage) and registers them as `databricks_mws_customer_managed_keys`.
- GovCloud parameterization via `databricks_gov_shard` input (commercial, civilian, dod) driving the correct Databricks control plane AWS account ID in KMS key policies.
- KMS key policies following the Databricks-documented pattern: customer account root full admin; control plane encrypt/decrypt for managed services; control plane DBFS + grants for storage; cross-account role EBS grants for storage.
- Automatic key rotation enabled and 7-day deletion window on both keys.
- Variable validation on `aws_partition`, `databricks_gov_shard`, `aws_account_id` (12-digit), `cross_account_role_arn` (IAM ARN format), `managed_services_key_alias` and `workspace_storage_key_alias` (must start with "alias/").
- Outputs: `managed_services_key_id`, `workspace_storage_key_id`, `managed_services_key_arn`, `workspace_storage_key_arn`, `managed_services_key_alias`, `workspace_storage_key_alias`, `databricks_control_plane_aws_account_id` (debug).
- `examples/basic/` — minimum invocation against commercial AWS.
- `tests/plan.tftest.hcl` — plan-command cases with `mock_provider` covering gov_shard branching and all variable validations.
- `tests/integration.tftest.hcl` — apply-command stub for live AWS + Databricks (credential-gated; includes a placeholder for the tier-failure case per DATABRICKS_RULES Rule 4.1).
